import SwiftUI

struct NewDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel2()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedWorkout: Workout?
    @State private var selectedUserWorkout: Workout?
    @State private var selectedExercise: Exercise?
    @State private var showPaywall = false
    @State private var showCreateWorkout = false
    @State private var showUserWorkoutDetail = false
    @State private var showWaterTracking = false
    @State private var showStepsTracking = false
    @State private var showWeightTracking = false
    @State private var showPlanGenerator = false
    @State private var showExerciseLibrary = false
    
    var userName: String {
        authViewModel.currentUser?.name ?? "User"
    }
    
    var isPremium: Bool {
        authViewModel.currentUser?.subscriptionStatus == .premium
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    DashboardHeaderView(
                        userName: userName,
                        profileImageName: nil
                    )
                    
                    // Streak Card
                    StreakCardView(streakData: viewModel.streakData) {
                        // Navigate to calendar tab
                        NotificationCenter.default.post(name: NSNotification.Name("NavigateToCalendar"), object: nil)
                        HapticFeedback.impact()
                    }
                    
                    // How To Section
                    if !viewModel.howToExercises.isEmpty {
                        HowToSectionView(exercises: viewModel.howToExercises) { exercise in
                            selectedExercise = exercise
                        }
                    }
                    
                    // Daily Tracker Card (only open water/steps when user is loaded)
                    DailyTrackerCardView(
                        dailyMetrics: viewModel.dailyMetrics,
                        onWeightTap: {
                            if authViewModel.currentUser?.id != nil {
                                showWeightTracking = true
                            }
                        },
                        onWaterTap: {
                            if authViewModel.currentUser?.id != nil {
                                showWaterTracking = true
                            }
                        },
                        onStepsTap: {
                            if authViewModel.currentUser?.id != nil {
                                showStepsTracking = true
                            }
                        }
                    )
                    
                    // My Workout Section
                    MyWorkoutSectionView(
                        actions: viewModel.workoutActions,
                        userWorkouts: viewModel.userWorkouts,
                        onActionTap: { actionType in
                            handleWorkoutAction(actionType)
                        },
                        onWorkoutTap: { workout in
                            handleUserWorkoutTap(workout)
                        }
                    )
                    
                    Spacer(minLength: 140)
                }
                .padding(.bottom, 20)
            }
            .refreshable {
                await viewModel.fetchDashboardData(userId: authViewModel.currentUser?.id)
            }
            .accessibilityHint("Pull down to refresh dashboard data")
        }
        .navigationBarHidden(true)
        .onAppear {
            AnalyticsService.shared.trackScreenView("NewDashboard", screenClass: "NewDashboardView")
            Task {
                await viewModel.fetchDashboardData(userId: authViewModel.currentUser?.id)
            }
        }
        .onChange(of: showCreateWorkout) { isPresented in
            // Refresh user workouts when returning from CreateWorkoutView
            if !isPresented {
                Task {
                    await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutCreated"))) { _ in
            // Refresh user workouts when a workout is created
            Task {
                await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutDeleted"))) { _ in
            // Refresh user workouts when a workout is deleted
            Task {
                await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id)
            }
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
        }
        .sheet(item: $selectedUserWorkout) { workout in
            UserWorkoutDetailView(workout: workout)
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
        // Check if this is a user-created workout
        if workout.userId != nil {
            selectedUserWorkout = workout
            HapticFeedback.impact()
        } else {
            // Fallback to regular workout handling
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
}

#Preview {
    NewDashboardView()
        .environmentObject(AuthViewModel())
}
