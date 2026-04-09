//
//  SyncManager.swift
//  GuineaDay
//
//  Created by Carol Zhou on 19/3/2026.
//

import Foundation
import FirebaseFirestore
import SwiftData

@MainActor
final class SyncManager: ObservableObject {
    private let db = Firestore.firestore()
    private var modelContext: ModelContext
    private var householdId: String
    private var listeners: [ListenerRegistration] = []
    private var pendingWeights: [UUID: [[String: Any]]] = [:]  // ← NEW: for race conditions

    init(modelContext: ModelContext, householdId: String) {
        self.modelContext = modelContext
        self.householdId = householdId
        startListeners()
    }

    private func houseRef() -> DocumentReference {
        db.collection("households").document(householdId)
    }

    // MARK: - Start All Listeners

    func startListeners() {

        // Tasks listener
        let taskListener = houseRef().collection("tasks").addSnapshotListener { [weak self] snap, error in
            guard let self, let snap else { return }
            Task { @MainActor in
                for change in snap.documentChanges {
                    let data = change.document.data()
                    switch change.type {
                    case .added, .modified:
                        self.upsertTask(data)
                    case .removed:
                        if let idStr = data["id"] as? String, let id = UUID(uuidString: idStr) {
                            self.deleteTask(id: id)
                        }
                    @unknown default: break
                    }
                }
            }
        }
        listeners.append(taskListener)

        // Piggies listener
        let piggyListener = houseRef().collection("pigs").addSnapshotListener { [weak self] snap, error in
            guard let self, let snap else { return }
            Task { @MainActor in
                for change in snap.documentChanges {
                    let data = change.document.data()
                    switch change.type {
                    case .added, .modified:
                        self.upsertPiggy(data)
                    case .removed:
                        if let idStr = data["id"] as? String, let id = UUID(uuidString: idStr) {
                            self.deletePiggy(id: id)
                        }
                    @unknown default: break
                    }
                }
            }
        }
        listeners.append(piggyListener)

        // Photos listener
        let photoListener = houseRef().collection("photos").addSnapshotListener { [weak self] snap, error in
            guard let self, let snap else { return }
            Task { @MainActor in
                for change in snap.documentChanges {
                    let data = change.document.data()
                    switch change.type {
                    case .added, .modified:
                        self.upsertPhoto(data)
                    case .removed:
                        if let idStr = data["id"] as? String, let id = UUID(uuidString: idStr) {
                            self.deletePhoto(id: id)
                        }
                    @unknown default: break
                    }
                }
            }
        }
        listeners.append(photoListener)

        // Weight logs listener (collectionGroup across all pigs)
        let weightListener = db.collectionGroup("weights").addSnapshotListener { [weak self] snap, error in
            guard let self, let snap else { return }
            Task { @MainActor in
                for change in snap.documentChanges {
                    // Only process docs that belong to our household
                    guard change.document.reference.path.contains(self.householdId) else { continue }
                    // Extract pigId from path: .../pigs/{pigId}/weights/{logId}
                    guard let pigIdStr = change.document.reference.parent.parent?.documentID,
                          let pigId = UUID(uuidString: pigIdStr) else { continue }

                    let data = change.document.data()
                    switch change.type {
                    case .added, .modified:
                        self.upsertWeightLog(data, pigId: pigId)
                    case .removed:
                        if let idStr = data["id"] as? String, let id = UUID(uuidString: idStr) {
                            self.deleteWeightLog(id: id)
                        }
                    @unknown default: break
                    }
                }
            }
        }
        listeners.append(weightListener)
    }

    // MARK: - Tasks

    private func upsertTask(_ data: [String: Any]) {
        guard
            let idStr    = data["id"] as? String,
            let id       = UUID(uuidString: idStr),
            let title    = data["title"] as? String,
            let dueDate  = (data["dueDate"] as? Timestamp)?.dateValue(),
            let category = data["category"] as? String,
            let priority = data["priority"] as? String
        else { return }

        let isRecurring     = data["isRecurring"]     as? Bool   ?? false
        let recurrenceRule  = data["recurrenceRule"]  as? String ?? "none"
        let reminderEnabled = data["reminderEnabled"] as? Bool   ?? false
        let reminderTime    = (data["reminderTime"]   as? Timestamp)?.dateValue()

        let predicate = #Predicate<TaskItem> { $0.id == id }
        let existing  = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first

        if let task = existing {
            task.title           = title
            task.isCompleted     = data["isCompleted"] as? Bool ?? false
            task.isRecurring     = isRecurring
            task.recurrenceRule  = recurrenceRule
            task.reminderEnabled = reminderEnabled
            task.reminderTime    = reminderTime
        } else {
            let task = TaskItem(title: title, dueDate: dueDate, category: category, priority: priority)
            task.id              = id
            task.isRecurring     = isRecurring
            task.recurrenceRule  = recurrenceRule
            task.reminderEnabled = reminderEnabled
            task.reminderTime    = reminderTime
            modelContext.insert(task)
            // Schedule notification on THIS device for tasks received from another device
            if reminderEnabled {
                NotificationService.shared.schedule(for: task)
            }
        }
        try? modelContext.save()
    }

    private func deleteTask(id: UUID) {
        let predicate = #Predicate<TaskItem> { $0.id == id }
        if let task = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            modelContext.delete(task)
            try? modelContext.save()
        }
    }

    // MARK: - Piggies

    private func upsertPiggy(_ data: [String: Any]) {
        guard
            let idStr = data["id"] as? String,
            let id    = UUID(uuidString: idStr),
            let name  = data["name"] as? String
        else { return }

        let predicate = #Predicate<GuineaPig> { $0.id == id }
        let existing  = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first

        if let piggy = existing {
            piggy.name  = name
            piggy.breed = data["breed"] as? String ?? piggy.breed
            piggy.gender = data["gender"] as? String ?? piggy.gender
            // Read either key name (old: "profileImageName", new: "profileImageAssetName")
            piggy.profileImageAssetName = data["profileImageAssetName"] as? String
                ?? data["profileImageName"] as? String
            if let ts = (data["birthDate"] as? Timestamp)?.dateValue() { piggy.birthDate = ts }
        } else {
            let piggy = GuineaPig(
                name:      name,
                birthDate: (data["birthDate"] as? Timestamp)?.dateValue() ?? Date(),
                breed:     data["breed"] as? String ?? "American",
                gender:    data["gender"] as? String ?? "Boar"
            )
            piggy.id = id
            piggy.profileImageAssetName = data["profileImageAssetName"] as? String
                ?? data["profileImageName"] as? String
            modelContext.insert(piggy)
        }
        try? modelContext.save()

        // NEW: Check for pending weights that arrived before the pig
        if let pending = pendingWeights[id] {
            for weightData in pending {
                upsertWeightLog(weightData, pigId: id)
            }
            pendingWeights.removeValue(forKey: id)
        }
    }

    private func deletePiggy(id: UUID) {
        let predicate = #Predicate<GuineaPig> { $0.id == id }
        if let piggy = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            modelContext.delete(piggy)
            try? modelContext.save()
        }
    }

    // MARK: - Photos

    private func upsertPhoto(_ data: [String: Any]) {
        guard
            let idStr    = data["id"] as? String,
            let id       = UUID(uuidString: idStr),
            let filename = data["filename"] as? String
        else { return }

        let predicate = #Predicate<Photo> { $0.id == id }
        let existing  = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first

        if let photo = existing {
            photo.filename = filename
            if let ts = (data["dateTaken"] as? Timestamp)?.dateValue() { photo.dateTaken = ts }
        } else {
            let photo = Photo(filename: filename)
            photo.id = id
            if let ts = (data["dateTaken"] as? Timestamp)?.dateValue() { photo.dateTaken = ts }
            modelContext.insert(photo)
        }
        try? modelContext.save()
    }


    private func deletePhoto(id: UUID) {
        let predicate = #Predicate<Photo> { $0.id == id }
        if let photo = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            modelContext.delete(photo)
            try? modelContext.save()
        }
    }
    // MARK: - Weight Logs

    private func upsertWeightLog(_ data: [String: Any], pigId: UUID) {
        guard
            let idStr       = data["id"] as? String,
            let id          = UUID(uuidString: idStr),
            let weightGrams = data["weightGrams"] as? Int
        else { return }

        // Fetch the pig first to attach the log
        let pigPredicate = #Predicate<GuineaPig> { $0.id == pigId }
        guard let pig = try? modelContext.fetch(FetchDescriptor<GuineaPig>(predicate: pigPredicate)).first else {
            // RACE CONDITION: Pig not found yet, queue the weight data
            if pendingWeights[pigId] == nil { pendingWeights[pigId] = [] }
            if !(pendingWeights[pigId]?.contains(where: { ($0["id"] as? String) == idStr }) ?? false) {
                pendingWeights[pigId]?.append(data)
            }
            return
        }

        let logPredicate = #Predicate<WeightLog> { $0.id == id }
        let existing = try? modelContext.fetch(FetchDescriptor<WeightLog>(predicate: logPredicate)).first

        if let log = existing {
            log.weightGrams = weightGrams
            if let ts = (data["date"] as? Timestamp)?.dateValue() { log.date = ts }
        } else {
            let log = WeightLog(
                date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                weightGrams: weightGrams
            )
            log.id = id
            log.guineaPig = pig
            modelContext.insert(log)
            // Ensure the pig's relationship is updated
            if !pig.weightLogs.contains(where: { $0.id == id }) {
                pig.weightLogs.append(log)
            }
        }
        try? modelContext.save()
    }

    private func deleteWeightLog(id: UUID) {
        let predicate = #Predicate<WeightLog> { $0.id == id }
        if let log = try? modelContext.fetch(FetchDescriptor<WeightLog>(predicate: predicate)).first {
            modelContext.delete(log)
            try? modelContext.save()
        }
    }


    // MARK: - Stop

    func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners = []
    }
}
