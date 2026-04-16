//
//  FirestoreService.swift
//  GuineaDay
//
//  Created by Carol Zhou on 19/3/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftData

@MainActor
final class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    var householdId: String
    
    init(householdId: String) {
        self.householdId = householdId
    }
    
    private func houseRef() -> DocumentReference {
        db.collection("households").document(householdId)
    }
    
    // MARK: - Tasks
    func addTask(_ task: TaskItem) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("tasks").document(task.id.uuidString).setData([
            "id":              task.id.uuidString,
            "title":           task.title,
            "dueDate":         task.dueDate,
            "isCompleted":     task.isCompleted,
            "category":        task.category,
            "priority":        task.priority,
            "createdAt":       task.createdAt,
            "isRecurring":     task.isRecurring,
            "recurrenceRule":  task.recurrenceRule,
            "reminderEnabled": task.reminderEnabled,
            "reminderTime":    task.reminderTime as Any
        ])
    }
    
    func updateTask(_ task: TaskItem) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("tasks").document(task.id.uuidString).updateData([
            "isCompleted": task.isCompleted,
            "completedAt": task.completedAt as Any
        ])
    }
    
    func deleteTask(id: UUID) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("tasks").document(id.uuidString).delete()
    }
    
    // MARK: - Guinea Pigs
    func savePig(_ pig: GuineaPig) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("pigs").document(pig.id.uuidString).setData([
            "id": pig.id.uuidString,
            "name": pig.name,
            "birthDate": pig.birthDate,
            "breed": pig.breed,
            "gender": pig.gender,
            "profileImageAssetName": pig.profileImageAssetName as Any
        ], merge: true)
    }
    
    func deletePig(id: UUID) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("pigs").document(id.uuidString).delete()
    }
    
    // MARK: - Weight Logs
    func addWeightLog(_ log: WeightLog, pigId: UUID) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("pigs").document(pigId.uuidString)
            .collection("weights").document(log.id.uuidString).setData([
                "id": log.id.uuidString,
                "date": log.date,
                "weightGrams": log.weightGrams
            ])
    }
    
    func deleteWeightLog(id: UUID, pigId: UUID) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("pigs").document(pigId.uuidString)
            .collection("weights").document(id.uuidString).delete()
    }
    
    // MARK: - Photos
    func addPhoto(_ photo: Photo) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("photos").document(photo.id.uuidString).setData([
            "id": photo.id.uuidString,
            "filename": photo.filename,
            "dateTaken": photo.dateTaken
        ])
    }
    
    func deletePhoto(id: UUID) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("photos").document(id.uuidString).delete()
    }
    
    // MARK: - Game Scores
    func saveScore(playerUid: String, game: String, score: Int) async throws {
        guard AppMode.current == .cloud else { return }
        try await houseRef().collection("scores").document(playerUid).setData([
            "uid": playerUid,
            "game": game,
            "score": score,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func listenToScores(onChange: @escaping ([String: Int]) -> Void) -> ListenerRegistration {
        // In local mode, return an immediately-removed dead handle — no Firestore connection kept open
        guard AppMode.current == .cloud else {
            let deadListener = houseRef().collection("scores").addSnapshotListener { _, _ in }
            deadListener.remove()
            return deadListener
        }
        return houseRef().collection("scores").addSnapshotListener { snap, _ in
            guard let snap else { return }
            var scores: [String: Int] = [:]
            for doc in snap.documents {
                if let uid = doc["uid"] as? String, let score = doc["score"] as? Int {
                    scores[uid] = score
                }
            }
            onChange(scores)
        }
    }

}
