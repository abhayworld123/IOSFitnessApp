import Foundation
import UserNotifications

enum FitnessLocalNotificationService {
    private static let workoutReminderId = "trakkit-workout-reminder"
    private static let streakAtRiskId = "trakkit-streak-at-risk"

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    static func reschedule(from prefs: NotificationPreferences, userName: String) async {
        await removeFitnessReminders()

        guard await requestAuthorizationIfNeeded() else { return }

        if prefs.workoutReminders {
            await scheduleWorkoutReminder(prefs: prefs, userName: userName)
        }
        if prefs.streakReminders {
            await scheduleStreakAtRiskReminder(userName: userName)
        }
    }

    static func removeFitnessReminders() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [workoutReminderId, streakAtRiskId]
        )
    }

    private static func scheduleWorkoutReminder(prefs: NotificationPreferences, userName: String) async {
        let copy = NotificationCopyBuilder.workoutReminder(name: userName)
        var comps = DateComponents()
        comps.hour = prefs.workoutReminderHour
        comps.minute = prefs.workoutReminderMinute

        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.message
        content.sound = .default
        content.userInfo = ["actionURL": "trakkit://dashboard"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: workoutReminderId, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func scheduleStreakAtRiskReminder(userName: String) async {
        let copy = NotificationCopyBuilder.streakAtRisk(name: userName, streakDays: 1)
        var comps = DateComponents()
        comps.hour = 20
        comps.minute = 0

        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.message
        content.sound = .default
        content.userInfo = ["actionURL": "trakkit://dashboard"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: streakAtRiskId, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
