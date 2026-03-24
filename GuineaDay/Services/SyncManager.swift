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

        let predicate = #Predicate<TaskItem> { $0.id == id }
        let existing  = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first

        if let task = existing {
            task.title       = title
            task.isCompleted = data["isCompleted"] as? Bool ?? false
        } else {
            let task = TaskItem(title: title, dueDate: dueDate, category: category, priority: priority)
            task.id = id   // ← set Firestore id so future syncs match correctly
            modelContext.insert(task)
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

    // MARK: - Stop

    func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners = []
    }
}
