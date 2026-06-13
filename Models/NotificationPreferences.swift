import Foundation

struct NotificationPreferences: Codable, Equatable {
    var workoutReminders: Bool = true
    var planUpdates: Bool = true
    var achievementNotifications: Bool = true
    var waterReminders: Bool = true
    var stepsReminders: Bool = true
    var streakReminders: Bool = true
    var marketingNotifications: Bool = false
    var emailNotifications: Bool = false
    var pushNotifications: Bool = true

    /// Local daily workout nudge (hour 0–23).
    var workoutReminderHour: Int = 18
    var workoutReminderMinute: Int = 0

    /// No push/local alerts between start and end hour (24h clock).
    var quietHoursStartHour: Int = 22
    var quietHoursEndHour: Int = 7

    var workoutReminderTime: Date {
        var comps = DateComponents()
        comps.hour = workoutReminderHour
        comps.minute = workoutReminderMinute
        return Calendar.current.date(from: comps) ?? Date()
    }

    mutating func setWorkoutReminderTime(_ date: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        workoutReminderHour = comps.hour ?? 18
        workoutReminderMinute = comps.minute ?? 0
    }

    func isWithinQuietHours(at date: Date = Date()) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        if quietHoursStartHour <= quietHoursEndHour {
            return hour >= quietHoursStartHour && hour < quietHoursEndHour
        }
        return hour >= quietHoursStartHour || hour < quietHoursEndHour
    }

    func allows(type: NotificationType) -> Bool {
        switch type {
        case .workout, .reminder:
            return workoutReminders
        case .plan:
            return planUpdates
        case .achievement:
            return achievementNotifications
        case .system:
            return marketingNotifications
        }
    }
}
