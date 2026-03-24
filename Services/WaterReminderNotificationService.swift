import Foundation
import UserNotifications

enum WaterReminderNotificationService {
    private static let categoryIdentifier = "WATER_REMINDER"
    private static let identifierPrefix = "water-reminder-"

    /// Request notification authorization. Call before scheduling.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Schedule daily repeating notifications at the given times (only hour and minute are used).
    static func scheduleReminders(at times: [Date]) async {
        await removeAllWaterReminders()
        guard !times.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "Stay hydrated 💧"
        content.body = "Time for a glass of water!"
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        for (index, time) in times.enumerated() {
            let components = calendar.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let identifier = "\(identifierPrefix)\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Remove all water reminder notifications.
    static func removeAllWaterReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let waterIds = pending
            .filter { $0.identifier.hasPrefix(identifierPrefix) }
            .map(\.identifier)
        guard !waterIds.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: waterIds)
    }
}
