import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Main app content
                MainTabView()
                    .environmentObject(authViewModel)
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
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            WorkoutPlanView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
            
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(AppConstants.Colors.primary)
    }
}

#Preview {
    ContentView()
}

