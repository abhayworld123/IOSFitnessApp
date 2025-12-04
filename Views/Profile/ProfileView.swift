import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showEditProfile = false
    @State private var showManageSubscription = false
    @State private var showNotificationSettings = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.totalWorkoutsCompleted == 0 {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // User Info Section
                            userInfoSection
                            
                            // Statistics Section
                            statisticsSection
                            
                            // Recent Workouts Section
                            if !viewModel.recentWorkouts.isEmpty {
                                recentWorkoutsSection
                            }
                            
                            // Settings Section
                            settingsSection
                            
                            // Sign Out Button
                            signOutButton
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showManageSubscription) {
                // Will be replaced with subscription management view
                PaywallView()
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .onAppear {
                Task {
                    await viewModel.fetchUserStatistics()
                }
                AnalyticsService.shared.trackScreenView("Profile", screenClass: "ProfileView")
            }
        }
    }
    
    // MARK: - User Info Section
    
    private var userInfoSection: some View {
        VStack(spacing: 16) {
            // Profile Picture Placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppConstants.Colors.primary,
                                AppConstants.Colors.secondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(initials)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(authViewModel.currentUser?.name ?? "User")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.system(size: 16))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                
                // Subscription Badge
                HStack(spacing: 6) {
                    Image(systemName: authViewModel.currentUser?.subscriptionStatus == .premium ? "crown.fill" : "lock.fill")
                        .font(.system(size: 12))
                    Text(authViewModel.currentUser?.subscriptionStatus.displayName ?? "Free")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(authViewModel.currentUser?.subscriptionStatus == .premium ? .yellow : AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    authViewModel.currentUser?.subscriptionStatus == .premium ?
                    Color.yellow.opacity(0.2) :
                    AppConstants.Colors.cardBackground(colorScheme: colorScheme)
                )
                .cornerRadius(12)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
        .padding(.horizontal, 20)
    }
    
    private var initials: String {
        guard let name = authViewModel.currentUser?.name else { return "U" }
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if !components.isEmpty {
            return String(components[0].prefix(2))
        }
        return "U"
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "checkmark.circle.fill",
                    title: "Workouts",
                    value: "\(viewModel.totalWorkoutsCompleted)",
                    color: AppConstants.Colors.success
                )
                
                StatCard(
                    icon: "clock.fill",
                    title: "Minutes",
                    value: "\(viewModel.totalTimeExercised)",
                    color: AppConstants.Colors.primary
                )
                
                StatCard(
                    icon: "flame.fill",
                    title: "Streak",
                    value: "\(viewModel.currentStreak)",
                    color: Color.orange
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Recent Workouts Section
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                .padding(.horizontal, 20)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.recentWorkouts.prefix(10)) { item in
                    RecentWorkoutRow(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "person.circle",
                    title: "Edit Profile",
                    color: AppConstants.Colors.primary
                ) {
                    showEditProfile = true
                }
                
                Divider()
                    .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                    .padding(.leading, 60)
                
                ThemeToggleRow()
                
                Divider()
                    .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                    .padding(.leading, 60)
                
                SettingsRow(
                    icon: "crown.fill",
                    title: "Manage Subscription",
                    color: .yellow
                ) {
                    showManageSubscription = true
                }
                
                Divider()
                    .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                    .padding(.leading, 60)
                
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notification Settings",
                    color: AppConstants.Colors.primary
                ) {
                    showNotificationSettings = true
                }
                
                Divider()
                    .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                    .padding(.leading, 60)
                
                SettingsRow(
                    icon: "lock.shield.fill",
                    title: "Privacy Policy",
                    color: AppConstants.Colors.primary
                ) {
                    showPrivacyPolicy = true
                }
                
                Divider()
                    .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                    .padding(.leading, 60)
                
                SettingsRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    color: AppConstants.Colors.primary
                ) {
                    showTermsOfService = true
                }
            }
            .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
            .cornerRadius(AppConstants.Design.cornerRadius)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Sign Out Button
    
    private var signOutButton: some View {
        Button(action: {
            authViewModel.signOut()
        }) {
            HStack {
                Image(systemName: "arrow.right.square")
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading profile...")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                .padding(.top, 16)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
}

// MARK: - Recent Workout Row

struct RecentWorkoutRow: View {
    let item: WorkoutHistoryItem
    @State private var workout: Workout?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnailURL = item.workout.thumbnailURL, !thumbnailURL.isEmpty {
                AsyncImage(url: URL(string: thumbnailURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .frame(width: 60, height: 60)
                    @unknown default:
                        Rectangle()
                            .fill(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .frame(width: 60, height: 60)
                    }
                }
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppConstants.Colors.primary,
                                AppConstants.Colors.secondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.workout.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                    .lineLimit(1)
                
                Text(formatDate(item.completedDate))
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            .padding()
        }
    }
}

// MARK: - Theme Toggle Row

struct ThemeToggleRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 20))
                .foregroundColor(AppConstants.Colors.primary)
                .frame(width: 24)
            
            Text("Theme")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            Spacer()
            
            Picker("Theme", selection: $themeManager.currentTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .tint(AppConstants.Colors.primary)
        }
        .padding()
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Name", text: $name)
                            .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                        
                        TextField("Email", text: $email)
                            .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    } header: {
                        Text("Profile Information")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(isLoading || name.isEmpty || email.isEmpty)
                }
            }
            .onAppear {
                name = authViewModel.currentUser?.name ?? ""
                email = authViewModel.currentUser?.email ?? ""
            }
        }
    }
    
    private func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await viewModel.updateProfile(name: name, email: email)
            await authViewModel.checkAuthenticationStatus()
            dismiss()
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
        
        isLoading = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

