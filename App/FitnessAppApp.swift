import SwiftUI
import FirebaseCore
import GoogleSignIn

enum AppState {
    case splash
    case main
}

@main
struct FitnessAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var appState: AppState = .splash
    
    init() {
        // Initialize Firebase
        FirebaseService.shared.configure()
        // Required for Google Sign-In on device (prevents "No active configuration" crash)
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case .splash:
                    SplashScreenView(isActive: Binding(
                        get: { appState == .splash },
                        set: { isActive in
                            if !isActive {
                                // Profile onboarding is gated inside ContentView after authentication + Firestore user.
                                withAnimation {
                                    appState = .main
                                }
                            }
                        }
                    ))
                    .transition(.opacity)
                    .zIndex(1)
                    
                case .main:
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(CategoryConfigStore.shared)
                        .task { await CategoryConfigStore.shared.reload() }
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .animation(.easeInOut(duration: 0.5), value: appState)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
