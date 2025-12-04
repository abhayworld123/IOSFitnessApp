import Foundation

enum FitnessGoal: String, Codable, CaseIterable {
    case weightLoss = "weightLoss"
    case muscleGain = "muscleGain"
    case flexibility = "flexibility"
    case endurance = "endurance"
    
    var displayName: String {
        switch self {
        case .weightLoss:
            return "Weight Loss"
        case .muscleGain:
            return "Muscle Gain"
        case .flexibility:
            return "Flexibility"
        case .endurance:
            return "Endurance"
        }
    }
    
    var icon: String {
        switch self {
        case .weightLoss:
            return "figure.walk"
        case .muscleGain:
            return "dumbbell.fill"
        case .flexibility:
            return "figure.flexibility"
        case .endurance:
            return "heart.fill"
        }
    }
}

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var name: String
    var fitnessGoal: FitnessGoal?
    var subscriptionStatus: SubscriptionStatus
    var createdAt: Date
    var currentWorkoutPlanId: String?
    
    init(
        id: String,
        email: String,
        name: String,
        fitnessGoal: FitnessGoal? = nil,
        subscriptionStatus: SubscriptionStatus = .free,
        createdAt: Date = Date(),
        currentWorkoutPlanId: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.fitnessGoal = fitnessGoal
        self.subscriptionStatus = subscriptionStatus
        self.createdAt = createdAt
        self.currentWorkoutPlanId = currentWorkoutPlanId
    }
}

