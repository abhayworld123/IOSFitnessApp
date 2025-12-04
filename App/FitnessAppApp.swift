import SwiftUI
import FirebaseCore

enum AppState {
    case splash
    case onboarding
    case main
}

@main
struct FitnessAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var appState: AppState = .splash
    
    init() {
        // Initialize Firebase
        FirebaseService.shared.configure()
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
                    OnboardingView(isPresented: Binding(
                        get: { appState == .onboarding },
                        set: { isPresented in
                            if !isPresented {
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
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .animation(.easeInOut(duration: 0.5), value: appState)
        }
    }
}

