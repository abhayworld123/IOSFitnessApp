import Foundation
import SwiftUI

// MARK: - Streak Data

struct StreakData: Codable {
    var weeklyActivities: [DayActivity]
    var currentStreak: Int
    
    var completedDays: Int {
        weeklyActivities.filter { $0.isCompleted }.count
    }
}

struct DayActivity: Codable, Identifiable {
    let id: String
    let dayName: String
    let date: Date
    var isCompleted: Bool
    
    init(dayName: String, date: Date, isCompleted: Bool = false) {
        self.id = UUID().uuidString
        self.dayName = dayName
        self.date = date
        self.isCompleted = isCompleted
    }
}

// MARK: - Daily Metrics

struct DailyMetrics: Codable {
    var weight: WeightMetric
    var water: WaterMetric
    var sleep: SleepMetric
    var steps: StepsMetric
}

struct WeightMetric: Codable {
    var current: Double // in kg
    var target: Double // in kg
    var lost: Double // in kg
    
    var displayText: String {
        if current <= 0 && target <= 0 {
            return "Start tracking weight"
        }
        return "Lost \(Int(lost)) kg"
    }
}

struct WaterMetric: Codable {
    var current: Int // glasses consumed
    var goal: Int // target glasses
    
    var displayText: String {
        if goal <= 0 {
            return "Start tracking water"
        }
        return "Goal: \(goal) glasses"
    }
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }
}

struct SleepMetric: Codable {
    var current: Double // hours slept
    var goal: Double // target hours
    
    var displayText: String {
        if goal <= 0 {
            return "Start tracking sleep"
        }
        return "Goal: \(Int(goal)) hours"
    }
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }
}

struct StepsMetric: Codable {
    var current: Int
    var goal: Int
    
    var displayText: String {
        if goal <= 0 {
            return "Start tracking steps"
        }
        return "\(current)/\(goal) steps"
    }
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }
}

// MARK: - Workout Quick Actions

struct WorkoutQuickAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let iconName: String
    let iconColor: Color
    let action: WorkoutActionType
}

enum WorkoutActionType {
    case newWorkout
    case customPlan
    case myExercises
}
