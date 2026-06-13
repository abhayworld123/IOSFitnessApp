import Foundation

enum FitnessGoal: String, Codable, CaseIterable {
    case weightLoss = "weightLoss"
    case muscleGain = "muscleGain"
    case flexibility = "flexibility"
    case endurance = "endurance"
    case both = "both"
    
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
        case .both:
            return "Both"
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
        case .both:
            return "figure.mixed.cardio"
        }
    }
    
    // Goals for the onboarding screen (three options)
    static let onboardingGoals: [FitnessGoal] = [
        .weightLoss,
        .muscleGain,
        .both
    ]
    
    // Display names for onboarding screen
    var onboardingDisplayName: String {
        switch self {
        case .weightLoss:
            return "Weight loss"
        case .muscleGain:
            return "Build muscles"
        case .both:
            return "Both"
        default:
            return displayName
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
    var weight: Double?
    var height: Double?
    var age: Int?
    var location: String?
    /// Profile onboarding (Firestore); optional for existing accounts.
    var gender: Gender?
    var activityLevel: ActivityLevel?
    var mealPreference: MealPreference?
    var physicalLimitations: [String]?
    var interestedActivities: [String]?
    var heightUnitPreference: HeightUnit?
    var weightUnitPreference: WeightUnit?
    /// Set when user finishes profile onboarding; legacy accounts may infer completion from filled profile fields.
    var profileOnboardingCompleted: Bool?
    
    init(
        id: String,
        email: String,
        name: String,
        fitnessGoal: FitnessGoal? = nil,
        subscriptionStatus: SubscriptionStatus = .free,
        createdAt: Date = Date(),
        currentWorkoutPlanId: String? = nil,
        weight: Double? = nil,
        height: Double? = nil,
        age: Int? = nil,
        location: String? = nil,
        gender: Gender? = nil,
        activityLevel: ActivityLevel? = nil,
        mealPreference: MealPreference? = nil,
        physicalLimitations: [String]? = nil,
        interestedActivities: [String]? = nil,
        heightUnitPreference: HeightUnit? = nil,
        weightUnitPreference: WeightUnit? = nil,
        profileOnboardingCompleted: Bool? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.fitnessGoal = fitnessGoal
        self.subscriptionStatus = subscriptionStatus
        self.createdAt = createdAt
        self.currentWorkoutPlanId = currentWorkoutPlanId
        self.weight = weight
        self.height = height
        self.age = age
        self.location = location
        self.gender = gender
        self.activityLevel = activityLevel
        self.mealPreference = mealPreference
        self.physicalLimitations = physicalLimitations
        self.interestedActivities = interestedActivities
        self.heightUnitPreference = heightUnitPreference
        self.weightUnitPreference = weightUnitPreference
        self.profileOnboardingCompleted = profileOnboardingCompleted
    }
}

extension User {
    /// Whether profile onboarding is done. New users must finish the flow (`profileOnboardingCompleted == true`).
    /// Legacy accounts (nil flag) infer completion from core vitals only so partial optional steps do not dismiss onboarding early.
    var hasCompletedProfileOnboarding: Bool {
        if profileOnboardingCompleted == true { return true }
        if profileOnboardingCompleted == false { return false }
        return gender != nil
            && age != nil
            && weight != nil
            && height != nil
    }
}

