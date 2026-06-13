import Foundation

enum VideoSourceType: String, Codable {
    case directURL = "directURL"
    case youtube = "youtube"
    case vimeo = "vimeo"
}

enum WorkoutCategory: String, Codable, CaseIterable {
    case all = "all"
    case strength = "strength"
    case cardio = "cardio"
    case yoga = "yoga"
    case hiit = "hiit"
    case flexibility = "flexibility"
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .strength:
            return "Strength"
        case .cardio:
            return "Cardio"
        case .yoga:
            return "Yoga"
        case .hiit:
            return "HIIT"
        case .flexibility:
            return "Flexibility"
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .strength:
            return "dumbbell.fill"
        case .cardio:
            return "heart.fill"
        case .yoga:
            return "figure.flexibility"
        case .hiit:
            return "bolt.fill"
        case .flexibility:
            return "figure.strengthtraining.functional"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case allLevels = "allLevels"
    
    var displayName: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        case .allLevels:
            return "All Levels"
        }
    }
    
    var color: String {
        switch self {
        case .beginner:
            return "#4CAF50" // Green
        case .intermediate:
            return "#FF9800" // Orange
        case .advanced:
            return "#F44336" // Red
        case .allLevels:
            return "#2196F3" // Blue
        }
    }
}

struct Workout: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var category: WorkoutCategory
    var difficulty: DifficultyLevel
    var duration: Int // in minutes
    var videoURL: String?
    var videoSourceType: VideoSourceType?
    var videoId: String? // For YouTube/Vimeo video IDs
    var thumbnailURL: String?
    var isPremium: Bool
    var exercises: [String] // Array of exercise IDs
    var caloriesBurned: Int // Estimated calories
    var userId: String? // User who created this workout
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        category: WorkoutCategory,
        difficulty: DifficultyLevel,
        duration: Int,
        videoURL: String? = nil,
        videoSourceType: VideoSourceType? = nil,
        videoId: String? = nil,
        thumbnailURL: String? = nil,
        isPremium: Bool = false,
        exercises: [String] = [],
        caloriesBurned: Int = 0,
        userId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.duration = duration
        self.videoURL = videoURL
        self.videoSourceType = videoSourceType
        self.videoId = videoId
        self.thumbnailURL = thumbnailURL
        self.isPremium = isPremium
        self.exercises = exercises
        self.caloriesBurned = caloriesBurned
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Workout {
    /// Local-only template for the first-time Quick Workout flow (bundle exercises `ex_001`…`ex_003`).
    static func quickStarterTemplate() -> Workout {
        Workout(
            id: "trakkit_quick_start_template",
            title: "Quick Workout",
            description: "Starter back session for new members.",
            category: .strength,
            difficulty: .beginner,
            duration: 25,
            exercises: ["ex_001", "ex_002", "ex_003"],
            caloriesBurned: 140,
            userId: nil
        )
    }
}

