import Foundation
import FirebaseFirestore

@MainActor
final class NotificationTriggerService {
    static let shared = NotificationTriggerService()

    private let db = Firestore.firestore()
    private let notificationService = NotificationService.shared
    private let prefsService = NotificationPreferencesService.shared

    private init() {}

    /// Run on dashboard open: update activity, evaluate inbox triggers, refresh local schedules.
    func runSessionChecks(
        userId: String,
        user: User,
        streakData: StreakData,
        userWorkouts: [Workout]
    ) async {
        let inactiveDays = await inactiveDays(for: userId)
        await updateLastActive(userId: userId)
        let prefs = await prefsService.load(for: userId)

        await FitnessLocalNotificationService.reschedule(from: prefs, userName: user.name)

        if prefs.pushNotifications {
            await PushNotificationService.shared.registerIfNeeded(userId: userId)
        }

        let completedToday = hasWorkoutCompletedToday(streakData: streakData)
        let hour = Calendar.current.component(.hour, from: Date())
        let dayKey = Self.dayKey(for: Date())

        if prefs.workoutReminders, !completedToday, hour >= 20, streakData.currentStreak > 0 {
            let workoutTitle = userWorkouts.first?.title
            let copy = NotificationCopyBuilder.missedWorkout(name: user.name, workoutTitle: workoutTitle)
            await createInboxIfAbsent(
                userId: userId,
                scenarioKey: "missed_workout_\(dayKey)",
                type: .workout,
                title: copy.title,
                message: copy.message,
                actionURL: userWorkouts.first.map { "trakkit://workout/\($0.id)/start" } ?? "trakkit://dashboard"
            )
        }

        if prefs.streakReminders, !completedToday, hour >= 18, streakData.currentStreak >= 2 {
            let copy = NotificationCopyBuilder.streakAtRisk(
                name: user.name,
                streakDays: streakData.currentStreak
            )
            await createInboxIfAbsent(
                userId: userId,
                scenarioKey: "streak_at_risk_\(dayKey)",
                type: .reminder,
                title: copy.title,
                message: copy.message,
                actionURL: "trakkit://dashboard"
            )
        }

        if let inactiveDays, inactiveDays >= 3 {
            let copy = NotificationCopyBuilder.inactiveUser(name: user.name, inactiveDays: inactiveDays)
            await createInboxIfAbsent(
                userId: userId,
                scenarioKey: "inactive_\(inactiveDays)d",
                type: .system,
                title: copy.title,
                message: copy.message,
                actionURL: "trakkit://dashboard"
            )
        }

        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 2, prefs.planUpdates {
            let completedThisWeek = streakData.weeklyActivities.filter(\.isCompleted).count
            let copy = NotificationCopyBuilder.weeklySummary(
                name: user.name,
                workoutsCompleted: completedThisWeek,
                streakDays: streakData.currentStreak
            )
            let weekKey = Self.weekKey(for: Date())
            await createInboxIfAbsent(
                userId: userId,
                scenarioKey: "weekly_summary_\(weekKey)",
                type: .plan,
                title: copy.title,
                message: copy.message,
                actionURL: "trakkit://calendar"
            )
        }
    }

    private func updateLastActive(userId: String) async {
        do {
            try await db.collection(FirestoreCollections.users).document(userId).setData([
                FirestoreFields.lastActiveAt: Timestamp(date: Date()),
                FirestoreFields.updatedAt: Timestamp(date: Date())
            ], merge: true)
        } catch {
            print("lastActiveAt update: \(error.localizedDescription)")
        }
    }

    private func inactiveDays(for userId: String) async -> Int? {
        do {
            let doc = try await db.collection(FirestoreCollections.users).document(userId).getDocument()
            guard let ts = doc.data()?[FirestoreFields.lastActiveAt] as? Timestamp else { return nil }
            let last = ts.dateValue()
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            return days >= 3 ? days : nil
        } catch {
            return nil
        }
    }

    private func hasWorkoutCompletedToday(streakData: StreakData) -> Bool {
        streakData.weeklyActivities.contains { act in
            Calendar.current.isDateInToday(act.date) && act.isCompleted
        }
    }

    private func createInboxIfAbsent(
        userId: String,
        scenarioKey: String,
        type: NotificationType,
        title: String,
        message: String,
        actionURL: String
    ) async {
        let docId = scenarioKey
        let ref = db.collection(FirestoreCollections.users)
            .document(userId)
            .collection(FirestoreCollections.notifications)
            .document(docId)

        do {
            let existing = try await ref.getDocument()
            if existing.exists { return }

            let notification = Notification(
                id: docId,
                type: type,
                title: title,
                message: message,
                timestamp: Date(),
                isRead: false,
                actionURL: actionURL,
                scenarioKey: scenarioKey
            )
            try await notificationService.createNotification(notification, userId: userId)
        } catch {
            print("createInboxIfAbsent: \(error.localizedDescription)")
        }
    }

    private static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }

    private static func weekKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-'W'ww"
        f.timeZone = .current
        return f.string(from: date)
    }
}
