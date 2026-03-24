import Foundation

/// Per-day activity stats stored under users/{userId}/dailyStats/{dateString}.
struct UserDailyStats: Codable, Identifiable {
    var id: String { dateString }
    let dateString: String // YYYY-MM-DD, used as document ID
    var date: Date
    var steps: Int
    var stepsGoal: Int
    var sleep: Double
    var sleepGoal: Double
    var weight: Double?
    var createdAt: Date
    var updatedAt: Date

    init(
        dateString: String? = nil,
        date: Date,
        steps: Int = 0,
        stepsGoal: Int = 10_000,
        sleep: Double = 0,
        sleepGoal: Double = 7,
        weight: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = cal.timeZone
        self.dateString = dateString ?? formatter.string(from: dayStart)
        self.date = dayStart
        self.steps = steps
        self.stepsGoal = stepsGoal
        self.sleep = sleep
        self.sleepGoal = sleepGoal
        self.weight = weight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func dateString(for date: Date) -> String {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = cal.timeZone
        return formatter.string(from: dayStart)
    }
}
