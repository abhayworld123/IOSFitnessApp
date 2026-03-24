import Foundation

struct ExerciseLog: Identifiable, Codable {
    let id: String
    let exerciseId: String
    let workoutId: String
    let userId: String
    var sets: [ExerciseSet]
    let date: Date
    var restTime: Int // in seconds
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        exerciseId: String,
        workoutId: String,
        userId: String,
        sets: [ExerciseSet] = [],
        date: Date = Date(),
        restTime: Int = 120,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.workoutId = workoutId
        self.userId = userId
        self.sets = sets
        self.date = date
        self.restTime = restTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ExerciseSet: Identifiable, Codable {
    let id: String
    var reps: Int
    var weight: Double // in kgs
    var setNumber: Int
    var note: String?
    var completedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        reps: Int,
        weight: Double,
        setNumber: Int,
        note: String? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.setNumber = setNumber
        self.note = note
        self.completedAt = completedAt
    }
}

enum LogTab: String, CaseIterable {
    case sets = "Sets"
    case analyze = "Analyze"
}
