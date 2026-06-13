import Foundation

enum NotificationCopyBuilder {
    static func workoutReminder(name: String) -> (title: String, message: String) {
        let first = firstName(from: name)
        return (
            "Time to train, \(first)",
            "Your workout is on the schedule. Open Trakkit and start your session."
        )
    }

    static func missedWorkout(name: String, workoutTitle: String?) -> (title: String, message: String) {
        let first = firstName(from: name)
        if let title = workoutTitle, !title.isEmpty {
            return (
                "\(first), you planned \(title) today",
                "Log a session or reschedule — consistency builds results."
            )
        }
        return (
            "\(first), your workout is still waiting",
            "You planned to train today. Tap to log a session or pick a workout."
        )
    }

    static func streakAtRisk(name: String, streakDays: Int) -> (title: String, message: String) {
        let first = firstName(from: name)
        return (
            "Don't lose your \(streakDays)-day streak",
            "\(first), a short session tonight keeps your momentum going."
        )
    }

    static func inactiveUser(name: String, inactiveDays: Int) -> (title: String, message: String) {
        let first = firstName(from: name)
        return (
            "We miss you, \(first)",
            "It's been \(inactiveDays) days — pick up where you left off with a quick workout."
        )
    }

    static func badgeUnlocked(name: String, badgeTitle: String) -> (title: String, message: String) {
        (
            "New badge unlocked",
            "\(firstName(from: name)), you earned \"\(badgeTitle)\" — keep going!"
        )
    }

    static func weeklySummary(name: String, workoutsCompleted: Int, streakDays: Int) -> (title: String, message: String) {
        let first = firstName(from: name)
        if workoutsCompleted == 0 {
            return (
                "Your week in review",
                "\(first), no workouts logged yet this week — start fresh today."
            )
        }
        return (
            "Your week in review",
            "\(first), you completed \(workoutsCompleted) workout\(workoutsCompleted == 1 ? "" : "s") and your streak is \(streakDays) days."
        )
    }

    static func auraFollowUp(name: String, topic: String) -> (title: String, message: String) {
        (
            "Aura checked in",
            "\(firstName(from: name)), ready to act on your \(topic) plan? Tap to open coach chat."
        )
    }

    private static func firstName(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "there" }
        return trimmed.components(separatedBy: " ").first ?? trimmed
    }
}
