import SwiftUI

private let profileBackground = Color(hex: "#F5F5F7")
private let profileCardWhite = Color.white
private let profileAccentOrange = Color(hex: "#FF9500")
private let profileTextPrimary = Color(hex: "#2A2A2A")
private let profileTextSecondary = Color(hex: "#8E8E93")

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showEditProfile = false
    @State private var showManageSubscription = false
    @State private var showNotifications = false
    @State private var showNotificationSettings = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showNewDashboard = false
    @State private var showNewOnboarding = false
    
    var body: some View {
        ZStack {
            profileBackground
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.totalWorkoutsCompleted == 0 && viewModel.monthlyChartData.isEmpty {
                loadingView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        userBlockSection
                        thisMonthSection
                        activitiesCardSection
                        badgesSection
                        bottomSettingsCardSection
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditProfile = true
                        } label: {
                            Label("Edit Profile", systemImage: "person.circle")
                        }
                        Button {
                            showNewDashboard = true
                        } label: {
                            Label("New Dashboard", systemImage: "chart.bar.fill")
                        }
                        Button {
                            showNewOnboarding = true
                        } label: {
                            Label("Preview Onboarding", systemImage: "figure.run")
                        }
                        Picker("Theme", selection: $themeManager.currentTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        Divider()
                        Button(role: .destructive) {
                            authViewModel.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(profileTextPrimary)
                    }
                }
            }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showManageSubscription) {
            PaywallView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
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
        .fullScreenCover(isPresented: $showNewDashboard) {
            NewDashboardView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showNewOnboarding) {
            NewOnboardingPreviewView()
        }
        .onAppear {
            Task {
                await viewModel.fetchUserStatistics()
            }
            AnalyticsService.shared.trackScreenView("Profile", screenClass: "ProfileView")
        }
    }
    
    // MARK: - User Block (avatar + name + location + metrics card)
    
    private var userBlockSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
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
                        .frame(width: 72, height: 72)
                    Text(initials)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.currentUser?.name ?? "User")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(profileTextPrimary)
                    Text(authViewModel.currentUser?.location ?? "New Delhi, Delhi, IN")
                        .font(.system(size: 14))
                        .foregroundColor(profileTextSecondary)
                }
                Spacer(minLength: 0)
            }
            
            HStack(spacing: 0) {
                metricsColumn(value: weightDisplay, label: "Weight")
                Rectangle()
                    .fill(profileTextSecondary.opacity(0.2))
                    .frame(width: 1, height: 44)
                metricsColumn(value: ageDisplay, label: "Age")
                Rectangle()
                    .fill(profileTextSecondary.opacity(0.2))
                    .frame(width: 1, height: 44)
                metricsColumn(value: heightDisplay, label: "Height")
            }
            .padding(.vertical, 16)
            .background(profileCardWhite)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
    
    private func metricsColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(profileTextPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(profileTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var weightDisplay: String {
        if let w = authViewModel.currentUser?.weight {
            return "\(Int(w)) KG"
        }
        return "80 KG"
    }
    
    private var ageDisplay: String {
        if let a = authViewModel.currentUser?.age {
            return "\(a)"
        }
        return "24"
    }
    
    private var heightDisplay: String {
        if let h = authViewModel.currentUser?.height {
            return "\(Int(h)) CM"
        }
        return "182 CM"
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
    
    // MARK: - This month
    
    private var thisMonthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This month")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(profileTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Workouts
            monthlyChartCard(title: "Workouts", data: viewModel.monthlyChartData.isEmpty ? placeholderMonthlyData : viewModel.monthlyChartData)
            // Steps
            monthlyChartCard(title: "Steps", data: viewModel.monthlyStepsData)
            // Water (glasses)
            monthlyChartCard(title: "Water (glasses)", data: viewModel.monthlyWaterData)
        }
    }
    
    private func monthlyChartCard(title: String, data: [DailyWorkoutData]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(profileTextSecondary)
            ProfileActivityChartWrapper(monthlyData: data.isEmpty ? placeholderMonthlyData : data)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(profileCardWhite)
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
    
    private var placeholderMonthlyData: [DailyWorkoutData] {
        let cal = Calendar.current
        let now = Date()
        return (0..<14).compactMap { offset in
            cal.date(byAdding: .day, value: -13 + offset, to: now).map { date in
                DailyWorkoutData(date: date, workoutsCompleted: [0, 0, 1, 0, 2, 1, 0, 1, 0, 0, 1, 2, 0, 1][offset], duration: 0, caloriesBurned: 0)
            }
        }
    }
    
    // MARK: - Activities card (Activities, Analytics, Saved)
    
    private var activitiesCardSection: some View {
        VStack(spacing: 0) {
            profileListRow(title: "Activities") {
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToCalendar"), object: nil)
            }
            profileListDivider
            profileListRow(title: "Analytics") {
                showNewDashboard = true
            }
            profileListDivider
            NavigationLink(destination: SavedView().environmentObject(authViewModel)) {
                profileListRowContent(title: "Saved")
            }
            .buttonStyle(.plain)
        }
        .background(profileCardWhite)
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
    
    private func profileListRowContent(title: String) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(profileTextPrimary)
            Spacer()
            ZStack {
                Circle()
                    .fill(profileAccentOrange)
                    .frame(width: 28, height: 28)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func profileListRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(profileTextPrimary)
                Spacer()
                ZStack {
                    Circle()
                        .fill(profileAccentOrange)
                        .frame(width: 28, height: 28)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
    
    private var profileListDivider: some View {
        Rectangle()
            .fill(profileTextSecondary.opacity(0.2))
            .frame(height: 1)
            .padding(.leading, 16)
    }
    
    // MARK: - Badges
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges \(viewModel.badges.count)")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(profileTextPrimary)
                Spacer()
                Button("View all") {}
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(profileAccentOrange)
            }
            .padding(.horizontal, 4)
            
            GeometryReader { geometry in
                let availableWidth = geometry.size.width - 32
                let spacing: CGFloat = 10
                let badgeWidth = (availableWidth - spacing * 3) / 4
                let iconSize: CGFloat = 36
                HStack(spacing: spacing) {
                    ForEach(viewModel.badges) { badge in
                        VStack(spacing: 6) {
                            Image(badge.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: iconSize, height: iconSize)
                            Text(badge.title)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(profileTextPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: badgeWidth)
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
            .frame(height: 88)
            .background(profileCardWhite)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
    
    // MARK: - Bottom Settings Card (Manage Subscription, Notifications, etc.)
    
    private var bottomSettingsCardSection: some View {
        VStack(spacing: 0) {
            bottomSettingsRow(icon: "crown.fill", iconColor: .yellow, title: "Manage Subscription") {
                showManageSubscription = true
            }
            profileListDivider
            bottomSettingsRow(icon: "bell.badge.fill", iconColor: profileAccentOrange, title: "Notifications") {
                showNotifications = true
            }
            profileListDivider
            bottomSettingsRow(icon: "bell.fill", iconColor: profileAccentOrange, title: "Notification Settings") {
                showNotificationSettings = true
            }
            profileListDivider
            bottomSettingsRow(icon: "lock.shield.fill", iconColor: profileAccentOrange, title: "Privacy Policy") {
                showPrivacyPolicy = true
            }
            profileListDivider
            bottomSettingsRow(icon: "doc.text.fill", iconColor: profileAccentOrange, title: "Terms of Service") {
                showTermsOfService = true
            }
        }
        .background(profileCardWhite)
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
    
    private func bottomSettingsRow(icon: String, iconColor: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 24, alignment: .center)
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(profileTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(profileTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading profile...")
                .font(.system(size: 16))
                .foregroundColor(profileTextSecondary)
                .padding(.top, 16)
        }
    }
}

// MARK: - Edit Profile View (unchanged)

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

// MARK: - Reusable components (kept for other views that use them)

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

struct RecentWorkoutRow: View {
    let item: WorkoutHistoryItem
    @State private var workout: Workout?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
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

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
