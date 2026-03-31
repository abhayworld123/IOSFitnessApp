import SwiftUI
import FirebaseCore
import GoogleSignIn

enum AppState {
    case splash
    case onboarding
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
                                // Check if onboarding has been completed
                                let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                                withAnimation {
                                    appState = hasCompletedOnboarding ? .main : .onboarding
                                }
                            }
                        }
                    ))
                    .transition(.opacity)
                    .zIndex(1)
                    
                case .onboarding:
                    NewOnboardingView(isPresented: Binding(
                        get: { appState == .onboarding },
                        set: { isPresented in
                            if !isPresented {
                                withAnimation {
                                    appState = .main
                                }
                            }
                        }
                    ))
                    .environmentObject(authViewModel)
                    .transition(.opacity)
                    .zIndex(1)
                    
                case .main:
                    ContentView()
                        .environmentObject(authViewModel)
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

