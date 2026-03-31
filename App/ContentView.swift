import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasCompletedNewOnboarding") private var hasCompletedNewOnboarding = false
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                ZStack {
                    MainTabView()
                        .environmentObject(authViewModel)
                    if !hasCompletedNewOnboarding {
                        NewOnboardingView(isPresented: Binding(
                            get: { !hasCompletedNewOnboarding },
                            set: { stillShowing in
                                if !stillShowing {
                                    hasCompletedNewOnboarding = true
                                }
                            }
                        ))
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                        .zIndex(1000)
                    }
                }
            } else {
                NavigationView {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    NavigationView {
                        NewDashboardView()
                            .environmentObject(authViewModel)
                    }
                case 1:
                    CalendarView(userId: authViewModel.currentUser?.id)
                        .environmentObject(authViewModel)
                case 2:
                    VideoLibraryView()
                        .environmentObject(authViewModel)
                case 3:
                    NavigationView {
                        ProfileView()
                            .environmentObject(authViewModel)
                    }
                default:
                    NavigationView {
                        NewDashboardView()
                            .environmentObject(authViewModel)
                    }
                }
            }
            
            // Custom Tab Bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
                    .accessibilityElement(children: .contain)
            }
        }
        .onAppear {
            // Hide default tab bar
            UITabBar.appearance().isHidden = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToCalendar"))) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = 1
            }
        }
    }
}

// MARK: - UIColor Extension for Hex
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

#Preview {
    ContentView()
}

