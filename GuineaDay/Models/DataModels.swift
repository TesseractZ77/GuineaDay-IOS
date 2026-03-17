import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var category: String
    var priority: String
    var createdAt: Date
    var completedAt: Date?
    
    init(title: String, dueDate: Date, category: String, priority: String) {
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = false
        self.category = category
        self.priority = priority
        self.createdAt = Date()
    }
}

@Model
final class GuineaPig {
    var id: UUID
    var name: String
    var birthDate: Date
    var breed: String
    var gender: String
    var profileImageAssetName: String? // Name of image saved to FileManager
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WeightLog.guineaPig)
    var weightLogs: [WeightLog] = []

    init(name: String, birthDate: Date, breed: String, gender: String) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.breed = breed
        self.gender = gender
    }
}

@Model
final class WeightLog {
    var id: UUID
    var date: Date
    var weightGrams: Int
    
    var guineaPig: GuineaPig?
    
    init(date: Date, weightGrams: Int) {
        self.id = UUID()
        self.date = date
        self.weightGrams = weightGrams
    }
}

@Model
final class Photo {
    var id: UUID
    var filename: String
    var dateTaken: Date
    
    init(filename: String) {
        self.id = UUID()
        self.filename = filename
        self.dateTaken = Date()
    }
}
