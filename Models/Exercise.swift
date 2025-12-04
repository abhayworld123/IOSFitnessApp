import Foundation

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case arms = "arms"
    case legs = "legs"
    case core = "core"
    case fullBody = "fullBody"
    case cardio = "cardio"
    
    var displayName: String {
        switch self {
        case .chest:
            return "Chest"
        case .back:
            return "Back"
        case .shoulders:
            return "Shoulders"
        case .arms:
            return "Arms"
        case .legs:
            return "Legs"
        case .core:
            return "Core"
        case .fullBody:
            return "Full Body"
        case .cardio:
            return "Cardio"
        }
    }
}

struct Exercise: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var sets: Int?
    var reps: Int?
    var duration: Int? // in seconds (for timed exercises)
    var restTime: Int // in seconds
    var animationURL: String? // Lottie JSON URL
    var muscleGroups: [MuscleGroup]
    var difficultyLevel: DifficultyLevel
    var instructions: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        sets: Int? = nil,
        reps: Int? = nil,
        duration: Int? = nil,
        restTime: Int = 30,
        animationURL: String? = nil,
        muscleGroups: [MuscleGroup],
        difficultyLevel: DifficultyLevel,
        instructions: [String],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.restTime = restTime
        self.animationURL = animationURL
        self.muscleGroups = muscleGroups
        self.difficultyLevel = difficultyLevel
        self.instructions = instructions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var isTimed: Bool {
        return duration != nil
    }
    
    var displayFormat: String {
        if let sets = sets, let reps = reps {
            return "\(sets) sets × \(reps) reps"
        } else if let duration = duration {
            return "\(duration) seconds"
        }
        return "Custom"
    }
}

