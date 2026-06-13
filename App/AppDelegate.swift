import UIKit
import FirebaseAuth
import FirebaseCore

/// Forwards remote notifications and APNs token to Firebase Auth so phone (OTP) sign-in works
/// when app delegate swizzling is not used (e.g. SwiftUI-only app).
/// On simulator we skip APNs so Firebase Auth never runs setAPNSToken (avoids internal exceptions/pauses).
final class AppDelegate: NSObject, UIApplicationDelegate {
    private var apnsTokenType: AuthAPNSTokenType {
#if DEBUG
        return .sandbox
#else
        return .prod
#endif
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Ensure Firebase is configured before any APNs callbacks
        FirebaseService.shared.configure()

        // Do NOT register for remote notifications at launch.
        // We only register when phone auth is requested to avoid startup-time assertion crashes
        // observed in TestFlight builds during APNs credential updates.
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        #if !targetEnvironment(simulator)
        guard !deviceToken.isEmpty else { return }
        Task { @MainActor in
            PushNotificationService.shared.handleAPNSToken(deviceToken)
        }
        // Defer to avoid running in early-startup contexts.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Auth.auth().setAPNSToken(deviceToken, type: self.apnsTokenType)
        }
        #endif
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        Task { @MainActor in
            PushNotificationService.shared.handleRemoteNotification(userInfo)
        }
        completionHandler(.newData)
    }
}
