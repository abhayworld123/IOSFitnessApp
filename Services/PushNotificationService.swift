import Foundation
import UIKit
import FirebaseFirestore
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

@MainActor
final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    private let db = Firestore.firestore()
    private var registeredUserId: String?

    private override init() {
        super.init()
    }

    func registerIfNeeded(userId: String) async {
        guard registeredUserId != userId else { return }
        registeredUserId = userId

        #if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
        #endif

        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        await saveFCMTokenIfAvailable(userId: userId)
    }

    func handleAPNSToken(_ deviceToken: Data) {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        if let actionURL = userInfo["actionURL"] as? String {
            NotificationDeepLink.post(actionURL: actionURL)
        }
    }

    private func saveFCMTokenIfAvailable(userId: String) async {
        #if canImport(FirebaseMessaging)
        do {
            let token = try await Messaging.messaging().token()
            guard !token.isEmpty else { return }
            try await db.collection(FirestoreCollections.users).document(userId).setData([
                FirestoreFields.fcmTokens: FieldValue.arrayUnion([token]),
                FirestoreFields.updatedAt: Timestamp(date: Date())
            ], merge: true)
        } catch {
            print("FCM token save: \(error.localizedDescription)")
        }
        #endif
    }
}

#if canImport(FirebaseMessaging)
extension PushNotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        Task { @MainActor in
            guard let userId = registeredUserId else { return }
            do {
                try await db.collection(FirestoreCollections.users).document(userId).setData([
                    FirestoreFields.fcmTokens: FieldValue.arrayUnion([fcmToken]),
                    FirestoreFields.updatedAt: Timestamp(date: Date())
                ], merge: true)
            } catch {
                print("FCM token refresh save: \(error.localizedDescription)")
            }
        }
    }
}
#endif
