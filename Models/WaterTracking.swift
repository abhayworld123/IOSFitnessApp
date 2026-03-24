import Foundation

struct WaterIntakeRecord: Identifiable, Codable {
    let id: String
    let userId: String
    let date: Date
    var glassesConsumed: Int
    var goal: Int // glasses per day
    var glassSize: Int // ml per glass (default 250)
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        date: Date = Date(),
        glassesConsumed: Int = 0,
        goal: Int = 12,
        glassSize: Int = 250,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.glassesConsumed = glassesConsumed
        self.goal = goal
        self.glassSize = glassSize
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var currentML: Int {
        return glassesConsumed * glassSize
    }
    
    var targetML: Int {
        return goal * glassSize
    }
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(glassesConsumed) / Double(goal), 1.0)
    }
    
    var remaining: Int {
        return max(0, goal - glassesConsumed)
    }
}

struct WaterReminder: Identifiable, Codable {
    let id: String
    let userId: String
    var isEnabled: Bool
    var reminderTimes: [Date] // Array of times for daily reminders
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        isEnabled: Bool = false,
        reminderTimes: [Date] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.isEnabled = isEnabled
        self.reminderTimes = reminderTimes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
