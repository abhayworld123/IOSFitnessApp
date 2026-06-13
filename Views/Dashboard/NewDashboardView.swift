import SwiftUI

// MARK: - Design reference (Trakkit home)
// Figma: https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=14-4
// Screenshot (local): .cursor/projects/Users-abhaymac-Desktop-screenshot2-projects-FitnessApp/assets/Screenshot_2026-04-14_at_12.24.45_PM-41a8b659-1d35-43c6-8b04-f81f81c9044f.png

struct NewDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel2()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedWorkout: Workout?
    @State private var selectedUserWorkout: Workout?
    @State private var selectedExercise: Exercise?
    @State private var showPaywall = false
    @State private var showCreateWorkout = false
    @State private var showQuickStarterSession = false
    @State private var showWaterTracking = false
    @State private var showStepsTracking = false
    @State private var showWeightTracking = false
    @State private var showSleepTracking = false
    @State private var showPlanGenerator = false
    @State private var showExerciseLibrary = false
    @State private var showCoachChat = false
    @State private var showAIWorkoutPlanFlow = false
    @State private var showSearchSheet = false
    @State private var showNotificationsSheet = false

    var userName: String {
        authViewModel.currentUser?.name ?? "User"
    }

    var isPremium: Bool {
        authViewModel.currentUser?.subscriptionStatus == .premium
    }
    
    var isFirstTimeHomeState: Bool {
        viewModel.isFirstTimeHomeEmptyState
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppConstants.TrakkitHome.background
                .ignoresSafeArea()

            if let err = viewModel.errorMessage, !viewModel.isLoading {
                LoadFailureFallbackView(
                    message: err,
                    onRetry: {
                        Task { await viewModel.fetchDashboardData(userId: authViewModel.currentUser?.id) }
                    },
                    onGoBack: nil
                )
            } else {
                ScrollView {
                VStack(spacing: 20) {
                    DashboardHeaderView(
                        userName: userName,
                        profileImageURL: nil,
                        unreadNotificationCount: notificationViewModel.unreadCount,
                        useWelcomeGreeting: isFirstTimeHomeState,
                        onSearchTap: { showSearchSheet = true },
                        onNotificationsTap: { showNotificationsSheet = true }
                    )

                    UpcomingSessionCardView(
                        session: viewModel.upcomingSession(for: authViewModel.currentUser),
                        isFirstTimeUser: isFirstTimeHomeState,
                        userName: userName,
                        onFilledCardTap: {
                            if let w = viewModel.userWorkouts.first, w.userId != nil {
                                selectedUserWorkout = w
                                HapticFeedback.impact()
                            }
                        },
                        onCreateTap: {
                            showCreateWorkout = true
                            HapticFeedback.impact()
                        },
                        onStartFirstWorkoutTap: {
                            showQuickStarterSession = true
                            HapticFeedback.impact()
                        }
                    )
                    .padding(.horizontal, 20)

                    if isFirstTimeHomeState {
                        HomeAIPlanBannerView {
                            showAIWorkoutPlanFlow = true
                            HapticFeedback.impact()
                        }
                        .padding(.horizontal, 20)

                        homeDailyTracker(firstTimeEmpty: true)

                        StreakCardView(
                            streakData: viewModel.streakData,
                            personalBest: viewModel.streakPersonalBest,
                            isFirstTimeUser: true,
                            onViewCalendar: {
                                NotificationCenter.default.post(name: NSNotification.Name("NavigateToCalendar"), object: nil)
                                HapticFeedback.impact()
                            }
                        )
                    } else {
                        StreakCardView(
                            streakData: viewModel.streakData,
                            personalBest: viewModel.streakPersonalBest,
                            isFirstTimeUser: false,
                            onViewCalendar: {
                                NotificationCenter.default.post(name: NSNotification.Name("NavigateToCalendar"), object: nil)
                                HapticFeedback.impact()
                            }
                        )

                        if !viewModel.howToExercises.isEmpty {
                            HowToSectionView(exercises: viewModel.howToExercises) { exercise in
                                selectedExercise = exercise
                            }
                        }

                        homeDailyTracker(firstTimeEmpty: false)
                    }

                    MyWorkoutSectionView(
                        actions: viewModel.workoutActions,
                        userWorkouts: viewModel.userWorkouts,
                        isFirstTimeUser: isFirstTimeHomeState,
                        onActionTap: { actionType in
                            handleWorkoutAction(actionType)
                        },
                        onWorkoutTap: { workout in
                            handleUserWorkoutTap(workout)
                        }
                    )

                    Spacer(minLength: 180)
                }
                .padding(.bottom, 24)
            }
            .refreshable {
                await viewModel.fetchDashboardData(userId: authViewModel.currentUser?.id)
            }
            .accessibilityHint("Pull down to refresh dashboard data")

                homeFloatingActionButton
                    .padding(.trailing, 22)
                    .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            AnalyticsService.shared.trackScreenView("NewDashboard", screenClass: "NewDashboardView")
            notificationViewModel.startListening()
            Task {
                await notificationViewModel.fetchNotifications()
                await viewModel.fetchDashboardData(userId: authViewModel.currentUser?.id)
                await runNotificationChecks()
            }
        }
        .onDisappear {
            notificationViewModel.stopListening()
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationDeepLink.navigateNotification)) { note in
            handleDeepLink(note)
        }
        .onChange(of: showCreateWorkout) { _, isPresented in
            if !isPresented {
                Task {
                    await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutCreated"))) { _ in
            Task {
                await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutDeleted"))) { _ in
            Task {
                await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id)
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            DashboardExerciseSearchSheet(
                exercises: viewModel.exercises,
                onSelect: { exercise in
                    selectedExercise = exercise
                    showSearchSheet = false
                }
            )
        }
        .sheet(isPresented: $showNotificationsSheet) {
            NotificationsView(viewModel: notificationViewModel)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(item: $selectedWorkout) { workout in
            if workout.isPremium && !isPremium {
                PaywallView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        selectedWorkout = nil
                    }
            } else {
                VideoPlayerView(workout: workout)
            }
        }
        .fullScreenCover(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, workout: nil)
        }
        .fullScreenCover(isPresented: $showCreateWorkout) {
            CreateWorkoutView()
                .environmentObject(authViewModel)
                .environmentObject(CategoryConfigStore.shared)
        }
        .fullScreenCover(isPresented: $showCoachChat) {
            CoachChatView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showAIWorkoutPlanFlow) {
            AIWorkoutPlanFlowView { workout in
                selectedUserWorkout = workout
                Task {
                    await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id)
                }
            }
            .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showQuickStarterSession) {
            WorkoutSessionStartView(
                workout: Workout.quickStarterTemplate(),
                userId: authViewModel.currentUser?.id ?? "",
                presentation: .quickStarterFirstWorkout
            )
            .environmentObject(authViewModel)
        }
        .fullScreenCover(item: $selectedUserWorkout) { workout in
            WorkoutSessionStartView(
                workout: workout,
                userId: authViewModel.currentUser?.id ?? ""
            )
            .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showWaterTracking) {
            if let userId = authViewModel.currentUser?.id {
                WaterTrackingView(userId: userId)
            } else {
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showStepsTracking) {
            if let userId = authViewModel.currentUser?.id {
                StepsTrackingView(
                    userId: userId,
                    stepsMetric: viewModel.dailyMetrics.steps
                )
            } else {
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showWeightTracking) {
            if let userId = authViewModel.currentUser?.id {
                WeightTrackingView(userId: userId)
            } else {
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showSleepTracking) {
            if let userId = authViewModel.currentUser?.id {
                SleepTrackerView(userId: userId)
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showPlanGenerator) {
            NavigationStack {
                PlanGeneratorView()
                    .environmentObject(authViewModel)
            }
        }
        .sheet(isPresented: $showExerciseLibrary) {
            NavigationStack {
                ExerciseLibraryView(exercises: viewModel.exercises)
            }
        }
        .onChange(of: showWeightTracking) { _, isPresented in
            if !isPresented {
                Task {
                    await viewModel.fetchDashboardData(userId: authViewModel.currentUser?.id)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func homeDailyTracker(firstTimeEmpty: Bool) -> some View {
        DailyTrackerCardView(
            dailyMetrics: viewModel.dailyMetrics,
            previousDayWeight: viewModel.previousDayWeight,
            isFirstTimeUser: firstTimeEmpty,
            onWeightTap: {
                if authViewModel.currentUser?.id != nil {
                    showWeightTracking = true
                }
            },
            onWaterTap: {
                if authViewModel.currentUser?.id != nil {
                    showWaterTracking = true
                    HapticFeedback.impact()
                }
            },
            onStepsTap: {
                if authViewModel.currentUser?.id != nil {
                    showStepsTracking = true
                }
            },
            onSleepTap: {
                if authViewModel.currentUser?.id != nil {
                    showSleepTracking = true
                    HapticFeedback.impact()
                }
            }
        )
    }

    private var homeFloatingActionButton: some View {
        Button {
            showCoachChat = true
            HapticFeedback.impact()
        } label: {
            ZStack {
                Circle()
                    .fill(AppConstants.TrakkitHome.accentOrange)
                    .frame(width: 58, height: 58)
                    .shadow(color: AppConstants.TrakkitHome.accentOrange.opacity(0.35), radius: 12, x: 0, y: 6)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 4, y: -4)
                    }
            }
        }
        .accessibilityLabel("Aura AI coach chat")
    }

    // MARK: - Helper Methods

    private func handleWorkoutTap(_ workout: Workout) {
        if workout.isPremium && !isPremium {
            selectedWorkout = workout
            showPaywall = true
            HapticFeedback.error()
        } else {
            selectedWorkout = workout
            HapticFeedback.impact()
        }
    }

    private func handleUserWorkoutTap(_ workout: Workout) {
        if workout.userId != nil {
            selectedUserWorkout = workout
            HapticFeedback.impact()
        } else {
            handleWorkoutTap(workout)
        }
    }

    private func handleWorkoutAction(_ actionType: WorkoutActionType) {
        switch actionType {
        case .newWorkout:
            showCreateWorkout = true
            HapticFeedback.impact()

        case .customPlan:
            showPlanGenerator = true
            HapticFeedback.impact()

        case .myExercises:
            showExerciseLibrary = true
            HapticFeedback.impact()
        }
    }

    private func runNotificationChecks() async {
        guard let user = authViewModel.currentUser else { return }
        await NotificationTriggerService.shared.runSessionChecks(
            userId: user.id,
            user: user,
            streakData: viewModel.streakData,
            userWorkouts: viewModel.userWorkouts
        )
    }

    private func handleDeepLink(_ note: Foundation.Notification) {
        guard let raw = note.userInfo?["destination"] as? String,
              let destination = NotificationDeepLink.Destination(rawValue: raw) else { return }

        showNotificationsSheet = false

        switch destination {
        case .dashboard:
            break
        case .water:
            showWaterTracking = true
        case .steps:
            showStepsTracking = true
        case .weight:
            showWeightTracking = true
        case .sleep:
            showSleepTracking = true
        case .calendar:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToCalendar"), object: nil)
        case .notifications:
            showNotificationsSheet = true
        case .workoutStart:
            if let workoutId = note.userInfo?["workoutId"] as? String,
               let workout = viewModel.userWorkouts.first(where: { $0.id == workoutId }) {
                selectedUserWorkout = workout
            } else if let workout = viewModel.userWorkouts.first {
                selectedUserWorkout = workout
            }
        }
    }
}

// MARK: - First-time home: AI plan banner

private struct HomeAIPlanBannerView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppConstants.TrakkitAI.iconBox)
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Generate a plan for me")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitAI.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("AI-powered routine based on your goals")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppConstants.TrakkitAI.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#C7C7CC"))
            }
            .padding(16)
            .background {
                LinearGradient(
                    colors: [
                        AppConstants.TrakkitAI.rowGradientTop,
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous)
                    .stroke(AppConstants.TrakkitAI.cardBorder.opacity(0.65), lineWidth: 1)
            )
            .shadow(
                color: AppConstants.TrakkitHome.cardShadowColor,
                radius: AppConstants.TrakkitHome.cardShadowRadius,
                x: 0,
                y: AppConstants.TrakkitHome.cardShadowY
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Generate a plan for me")
    }
}

// MARK: - Exercise search (home)

private struct DashboardExerciseSearchSheet: View {
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [Exercise] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return exercises }
        return exercises.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { exercise in
                Button {
                    onSelect(exercise)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppConstants.TrakkitHome.heading)
                        Text(exercise.difficultyLevel.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NewDashboardView()
        .environmentObject(AuthViewModel())
}
