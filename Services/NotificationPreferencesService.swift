import Foundation
import FirebaseFirestore

@MainActor
final class NotificationPreferencesService {
    static let shared = NotificationPreferencesService()

    private let db = Firestore.firestore()
    private let authService = AuthService.shared

    private init() {}

    func load(for userId: String) async -> NotificationPreferences {
        do {
            let doc = try await db.collection(FirestoreCollections.users)
                .document(userId)
                .collection("settings")
                .document("notifications")
                .getDocument()
            guard let data = doc.data() else { return NotificationPreferences() }
            return decode(from: data)
        } catch {
            print("NotificationPreferences load: \(error.localizedDescription)")
            return NotificationPreferences()
        }
    }

    func save(_ prefs: NotificationPreferences, userId: String) async {
        var data = encode(prefs)
        data["updatedAt"] = Timestamp(date: Date())
        do {
            try await db.collection(FirestoreCollections.users)
                .document(userId)
                .collection("settings")
                .document("notifications")
                .setData(data, merge: true)
        } catch {
            print("NotificationPreferences save: \(error.localizedDescription)")
        }
    }

    func loadForCurrentUser() async -> NotificationPreferences {
        guard let uid = authService.getCurrentAuthUser()?.uid else {
            return NotificationPreferences()
        }
        return await load(for: uid)
    }

    private func encode(_ prefs: NotificationPreferences) -> [String: Any] {
        [
            "workoutReminders": prefs.workoutReminders,
            "planUpdates": prefs.planUpdates,
            "achievementNotifications": prefs.achievementNotifications,
            "waterReminders": prefs.waterReminders,
            "stepsReminders": prefs.stepsReminders,
            "streakReminders": prefs.streakReminders,
            "marketingNotifications": prefs.marketingNotifications,
            "emailNotifications": prefs.emailNotifications,
            "pushNotifications": prefs.pushNotifications,
            "workoutReminderHour": prefs.workoutReminderHour,
            "workoutReminderMinute": prefs.workoutReminderMinute,
            "quietHoursStartHour": prefs.quietHoursStartHour,
            "quietHoursEndHour": prefs.quietHoursEndHour
        ]
    }

    private func decode(from data: [String: Any]) -> NotificationPreferences {
        var prefs = NotificationPreferences()
        prefs.workoutReminders = data["workoutReminders"] as? Bool ?? prefs.workoutReminders
        prefs.planUpdates = data["planUpdates"] as? Bool ?? prefs.planUpdates
        prefs.achievementNotifications = data["achievementNotifications"] as? Bool ?? prefs.achievementNotifications
        prefs.waterReminders = data["waterReminders"] as? Bool ?? prefs.waterReminders
        prefs.stepsReminders = data["stepsReminders"] as? Bool ?? prefs.stepsReminders
        prefs.streakReminders = data["streakReminders"] as? Bool ?? prefs.streakReminders
        prefs.marketingNotifications = data["marketingNotifications"] as? Bool ?? prefs.marketingNotifications
        prefs.emailNotifications = data["emailNotifications"] as? Bool ?? prefs.emailNotifications
        prefs.pushNotifications = data["pushNotifications"] as? Bool ?? prefs.pushNotifications
        prefs.workoutReminderHour = data["workoutReminderHour"] as? Int ?? prefs.workoutReminderHour
        prefs.workoutReminderMinute = data["workoutReminderMinute"] as? Int ?? prefs.workoutReminderMinute
        prefs.quietHoursStartHour = data["quietHoursStartHour"] as? Int ?? prefs.quietHoursStartHour
        prefs.quietHoursEndHour = data["quietHoursEndHour"] as? Int ?? prefs.quietHoursEndHour
        return prefs
    }
}
