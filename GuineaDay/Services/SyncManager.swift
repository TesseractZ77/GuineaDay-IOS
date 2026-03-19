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
    
    func startListeners() {
        // Tasks listener
        let taskListener = houseRef().collection("tasks").addSnapshotListener { [weak self] snap, _ in
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
        // Add similar listeners for pigs, photos as needed
    }
    
    private func upsertTask(_ data: [String: Any]) {
        guard
            let idStr = data["id"] as? String,
            let id = UUID(uuidString: idStr),
            let title = data["title"] as? String,
            let dueDate = (data["dueDate"] as? Timestamp)?.dateValue(),
            let category = data["category"] as? String,
            let priority = data["priority"] as? String
        else { return }
        
        let predicate = #Predicate<TaskItem> { $0.id == id }
        let existing = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first
        
        if let task = existing {
            task.title = title
            task.isCompleted = data["isCompleted"] as? Bool ?? false
        } else {
            let task = TaskItem(title: title, dueDate: dueDate, category: category, priority: priority)
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
    
    func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners = []
    }
    
    deinit {
        // Note: stopListeners() is async, call it before deinit in practice
    }
}
