import Foundation

/// Centralized Firestore collection names to avoid hardcoded strings
enum FirestoreCollections {
    static let users = "users"
    static let workouts = "workouts"
    static let exercises = "exercises"
    static let waterIntake = "waterIntake"
    static let waterReminders = "waterReminders"
    static let dailyStats = "dailyStats"
    static let userProgress = "userProgress"
    static let streaks = "streaks"
    static let workoutPlans = "workoutPlans"
    static let exerciseLogs = "exerciseLogs"
    static let badges = "badges"
    static let notifications = "notifications"
}

/// Common Firestore field names
enum FirestoreFields {
    static let userId = "userId"
    static let email = "email"
    static let name = "name"
    static let createdAt = "createdAt"
    static let updatedAt = "updatedAt"
    static let isPremium = "isPremium"
    static let category = "category"
    static let difficulty = "difficulty"
    static let title = "title"
    static let description = "description"
    static let duration = "duration"
    static let thumbnailURL = "thumbnailURL"
    static let videoURL = "videoURL"
    static let exercises = "exercises"
    static let completedWorkouts = "completedWorkouts"
    static let fitnessGoal = "fitnessGoal"
    static let subscriptionStatus = "subscriptionStatus"
    static let currentWorkoutPlanId = "currentWorkoutPlanId"
    static let weight = "weight"
    static let height = "height"
    static let age = "age"
    static let gender = "gender"
    static let activityLevel = "activityLevel"
    static let mealPreference = "mealPreference"
    static let physicalLimitations = "physicalLimitations"
    static let interestedActivities = "interestedActivities"
    static let heightUnitPreference = "heightUnitPreference"
    static let weightUnitPreference = "weightUnitPreference"
}
