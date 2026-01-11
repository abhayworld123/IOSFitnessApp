import Foundation
import FirebaseFirestore

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private let db = Firestore.firestore()
    private let authService = AuthService.shared
    private var listener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Fetch Notifications
    
    func fetchNotifications(userId: String) async throws -> [Notification] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        var notifications: [Notification] = []
        for document in snapshot.documents {
            var data = document.data()
            // Convert Firestore Timestamp to Date
            if let timestamp = data["timestamp"] as? Timestamp {
                data["timestamp"] = timestamp.dateValue()
            }
            if let notification = try? Firestore.Decoder().decode(Notification.self, from: data) {
                notifications.append(notification)
            }
        }
        return notifications
    }
    
    // MARK: - Real-time Listener
    
    func startListening(userId: String, onUpdate: @escaping ([Notification]) -> Void) {
        stopListening() // Remove existing listener if any
        
        listener = db.collection("users")
            .document(userId)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching notifications: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                var notifications: [Notification] = []
                for document in documents {
                    var data = document.data()
                    // Convert Firestore Timestamp to Date
                    if let timestamp = data["timestamp"] as? Timestamp {
                        data["timestamp"] = timestamp.dateValue()
                    }
                    if let notification = try? Firestore.Decoder().decode(Notification.self, from: data) {
                        notifications.append(notification)
                    }
                }
                
                Task { @MainActor in
                    onUpdate(notifications)
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(notificationId: String, userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .document(notificationId)
            .updateData(["isRead": true])
    }
    
    func markAllAsRead(userId: String) async throws {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        let batch = db.batch()
        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Delete Notification
    
    func deleteNotification(notificationId: String, userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .document(notificationId)
            .delete()
    }
    
    // MARK: - Create Notification
    
    func createNotification(_ notification: Notification, userId: String) async throws {
        var data = try Firestore.Encoder().encode(notification)
        // Convert Date to Firestore Timestamp
        data["timestamp"] = Timestamp(date: notification.timestamp)
        try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .document(notification.id)
            .setData(data)
    }
    
    // MARK: - Helper: Create Sample Notifications
    
    func createSampleNotifications(userId: String) async throws {
        let sampleNotifications: [Notification] = [
            Notification(
                type: .workout,
                title: "Workout Reminder",
                message: "Time for your evening workout! Don't forget to stay active.",
                timestamp: Date(),
                isRead: false
            ),
            Notification(
                type: .achievement,
                title: "Achievement Unlocked! 🎉",
                message: "Congratulations! You've completed 10 workouts this week.",
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                isRead: false
            ),
            Notification(
                type: .plan,
                title: "New Workout Plan Available",
                message: "A personalized workout plan has been created for you based on your goals.",
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isRead: true
            ),
            Notification(
                type: .reminder,
                title: "Water Intake Reminder",
                message: "Remember to drink water! You're at 60% of your daily goal.",
                timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                isRead: true
            ),
            Notification(
                type: .system,
                title: "App Update Available",
                message: "New features and improvements are available. Update now to get the latest experience.",
                timestamp: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                isRead: true
            )
        ]
        
        let batch = db.batch()
        for notification in sampleNotifications {
            var data = try Firestore.Encoder().encode(notification)
            data["timestamp"] = Timestamp(date: notification.timestamp)
            let ref = db.collection("users")
                .document(userId)
                .collection("notifications")
                .document(notification.id)
            batch.setData(data, forDocument: ref)
        }
        
        try await batch.commit()
    }
}

