import Foundation

struct WorkoutDay: Identifiable, Codable {
    let id: String
    var dayOfWeek: Int // 0 = Sunday, 1 = Monday, etc.
    var workoutId: String?
    var isRestDay: Bool
    var completed: Bool
    var completedDate: Date?
    
    init(
        id: String = UUID().uuidString,
        dayOfWeek: Int,
        workoutId: String? = nil,
        isRestDay: Bool = false,
        completed: Bool = false,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.workoutId = workoutId
        self.isRestDay = isRestDay
        self.completed = completed
        self.completedDate = completedDate
    }
    
    var dayName: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[dayOfWeek]
    }
    
    var shortDayName: String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[dayOfWeek]
    }
}

struct WorkoutPlan: Identifiable, Codable {
    let id: String
    var name: String
    var goal: FitnessGoal
    var durationWeeks: Int
    var workoutsPerWeek: Int
    var workouts: [WorkoutDay] // Ordered by day of week
    var userId: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var startDate: Date?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        goal: FitnessGoal,
        durationWeeks: Int,
        workoutsPerWeek: Int,
        workouts: [WorkoutDay] = [],
        userId: String,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        startDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.goal = goal
        self.durationWeeks = durationWeeks
        self.workoutsPerWeek = workoutsPerWeek
        self.workouts = workouts
        self.userId = userId
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.startDate = startDate
    }
    
    var completedWorkoutsCount: Int {
        return workouts.filter { $0.completed }.count
    }
    
    var totalWorkoutsCount: Int {
        return workouts.filter { !$0.isRestDay }.count
    }
    
    var progressPercentage: Double {
        guard totalWorkoutsCount > 0 else { return 0 }
        return Double(completedWorkoutsCount) / Double(totalWorkoutsCount) * 100
    }
    
    func getWorkoutForToday() -> WorkoutDay? {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        // Convert to 0-based (Sunday = 0)
        let dayIndex = (today + 5) % 7
        return workouts.first { $0.dayOfWeek == dayIndex }
    }
}

