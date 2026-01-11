import Foundation

// MARK: - Dashboard Metrics

struct DashboardMetrics: Codable {
    var bmi: BMIData
    var target: FitnessTarget
    var activityStatus: ActivityStatus
    var waterIntake: WaterIntake
    var calories: CalorieData
    var workoutProgress: WorkoutProgress
}

// MARK: - BMI Data

struct BMIData: Codable {
    let value: Double
    let height: Double // in cm
    let weight: Double // in kg
    let status: BMIStatus
    
    init(height: Double, weight: Double) {
        self.height = height
        self.weight = weight
        // BMI = weight (kg) / (height (m))^2
        let heightInMeters = height / 100.0
        self.value = weight / (heightInMeters * heightInMeters)
        self.status = BMIData.calculateStatus(self.value)
    }
    
    private static func calculateStatus(_ bmi: Double) -> BMIStatus {
        switch bmi {
        case ..<18.5:
            return .underweight
        case 18.5..<25:
            return .normal
        case 25..<30:
            return .overweight
        default:
            return .obese
        }
    }
}

enum BMIStatus: String, Codable {
    case underweight
    case normal
    case overweight
    case obese
    
    var displayName: String {
        switch self {
        case .underweight:
            return "Underweight"
        case .normal:
            return "Normal"
        case .overweight:
            return "Overweight"
        case .obese:
            return "Obese"
        }
    }
    
    var color: String {
        switch self {
        case .underweight:
            return "#2196F3" // Blue
        case .normal:
            return "#4CAF50" // Green
        case .overweight:
            return "#FF9800" // Orange
        case .obese:
            return "#F44336" // Red
        }
    }
}

// MARK: - Fitness Target

struct FitnessTarget: Codable {
    let goal: FitnessGoal
    let targetWeight: Double? // in kg
    let targetDate: Date?
    let currentProgress: Double // 0-100
    
    init(goal: FitnessGoal, targetWeight: Double? = nil, targetDate: Date? = nil, currentProgress: Double = 0) {
        self.goal = goal
        self.targetWeight = targetWeight
        self.targetDate = targetDate
        self.currentProgress = min(max(currentProgress, 0), 100)
    }
}

// MARK: - Activity Status

struct ActivityStatus: Codable {
    var steps: Int
    var stepsGoal: Int
    var activeMinutes: Int
    var activeMinutesGoal: Int
    var caloriesBurned: Int
    var caloriesBurnedGoal: Int
    
    var stepsProgress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(Double(steps) / Double(stepsGoal), 1.0)
    }
    
    var activeMinutesProgress: Double {
        guard activeMinutesGoal > 0 else { return 0 }
        return min(Double(activeMinutes) / Double(activeMinutesGoal), 1.0)
    }
    
    var caloriesBurnedProgress: Double {
        guard caloriesBurnedGoal > 0 else { return 0 }
        return min(Double(caloriesBurned) / Double(caloriesBurnedGoal), 1.0)
    }
}

// MARK: - Water Intake

struct WaterIntake: Codable {
    var current: Int // in ml
    var target: Int // in ml
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var remaining: Int {
        return max(target - current, 0)
    }
}

// MARK: - Calorie Data

struct CalorieData: Codable {
    var consumed: Int
    var burned: Int
    var target: Int
    
    var net: Int {
        return consumed - burned
    }
    
    var remaining: Int {
        return max(target - net, 0)
    }
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(consumed) / Double(target), 1.0)
    }
}

// MARK: - Workout Progress

struct WorkoutProgress: Codable {
    var weeklyData: [DailyWorkoutData]
    
    var totalWorkouts: Int {
        return weeklyData.reduce(0) { $0 + $1.workoutsCompleted }
    }
    
    var averageWorkoutsPerDay: Double {
        guard !weeklyData.isEmpty else { return 0 }
        return Double(totalWorkouts) / Double(weeklyData.count)
    }
}

struct DailyWorkoutData: Codable, Identifiable {
    let id: String
    let date: Date
    let workoutsCompleted: Int
    let duration: Int // in minutes
    let caloriesBurned: Int
    
    init(date: Date, workoutsCompleted: Int = 0, duration: Int = 0, caloriesBurned: Int = 0) {
        self.id = UUID().uuidString
        self.date = date
        self.workoutsCompleted = workoutsCompleted
        self.duration = duration
        self.caloriesBurned = caloriesBurned
    }
}





