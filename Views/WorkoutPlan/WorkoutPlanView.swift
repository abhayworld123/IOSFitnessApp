import SwiftUI

struct WorkoutPlanView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var showPlanGenerator = false
    @State private var selectedDay: WorkoutDay?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.currentPlan == nil {
                    loadingView
                } else if let ple = viewModel.planLoadError, !viewModel.isLoading {
                    LoadFailureFallbackView(
                        message: ple,
                        onRetry: { Task { await viewModel.fetchUserPlan() } },
                        onGoBack: nil
                    )
                } else if let plan = viewModel.currentPlan {
                    planView(plan: plan)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Workout Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.hasActivePlan {
                        Menu {
                            Button("Regenerate Plan") {
                                Task {
                                    await viewModel.regeneratePlan()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(AppConstants.Colors.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showPlanGenerator) {
                PlanGeneratorView()
            }
            .onAppear {
                if viewModel.currentPlan == nil && !viewModel.isLoading {
                    Task {
                        await viewModel.fetchUserPlan()
                    }
                }
            }
        }
    }
    
    // MARK: - Plan View
    
    private func planView(plan: WorkoutPlan) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Plan Header
                VStack(spacing: 12) {
                    Text(plan.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                    
                    // Progress Bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                            
                            Spacer()
                            
                            Text("\(plan.completedWorkoutsCount)/\(plan.totalWorkoutsCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                                    .frame(height: 8)
                                
                                Rectangle()
                                    .fill(AppConstants.Colors.primary)
                                    .frame(
                                        width: geometry.size.width * (plan.progressPercentage / 100),
                                        height: 8
                                    )
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding()
                    .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                    .cornerRadius(AppConstants.Design.cornerRadius)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Weekly Calendar
                VStack(alignment: .leading, spacing: 16) {
                    Text("This Week")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(plan.workouts) { day in
                            DayCard(
                                day: day,
                                isToday: isToday(dayOfWeek: day.dayOfWeek),
                                onTap: {
                                    selectedDay = day
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Today's Workout
                if let todayWorkout = plan.getWorkoutForToday(), !todayWorkout.isRestDay {
                    todayWorkoutCard(day: todayWorkout)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
        .sheet(item: $selectedDay) { day in
            if day.isRestDay {
                RestDaySheet(day: day)
            } else if let workoutId = day.workoutId {
                WorkoutDetailSheet(workoutId: workoutId, dayId: day.id, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Today's Workout Card
    
    private func todayWorkoutCard(day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Workout")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
                
                if day.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppConstants.Colors.success)
                }
            }
            
            if let workoutId = day.workoutId {
                // Fetch workout details (simplified - in production, fetch from service)
                Text("Workout ID: \(workoutId)")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            
            if !day.completed {
                Button(action: {
                    Task {
                        await viewModel.markWorkoutComplete(dayId: day.id)
                    }
                }) {
                    Text("Mark as Complete")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AppConstants.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(AppConstants.Design.cornerRadius)
                }
            }
        }
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
    
    // MARK: - Day Card
    
    private struct DayCard: View {
        let day: WorkoutDay
        let isToday: Bool
        let onTap: () -> Void
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    Text(day.shortDayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isToday ? .white : AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    
                    if day.isRestDay {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isToday ? .white.opacity(0.8) : AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.5))
                    } else if day.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isToday ? .white : AppConstants.Colors.success)
                    } else {
                        Image(systemName: "figure.run")
                            .font(.system(size: 20))
                            .foregroundColor(isToday ? .white : AppConstants.Colors.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(isToday ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isToday ? Color.clear : AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.5))
            
            Text("No Workout Plan")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            Text("Create a personalized workout plan based on your goals and preferences.")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showPlanGenerator = true
            }) {
                Text("Create Plan")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppConstants.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(AppConstants.Design.cornerRadius)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading plan...")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                .padding(.top, 16)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isToday(dayOfWeek: Int) -> Bool {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let todayIndex = (today + 5) % 7 // Convert to 0-based (Sunday = 0)
        return dayOfWeek == todayIndex
    }
}

// MARK: - Workout Detail Sheet

struct WorkoutDetailSheet: View {
    let workoutId: String
    let dayId: String
    @ObservedObject var viewModel: WorkoutPlanViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var workout: Workout?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showVideoPlayer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading workout...")
                            .font(.system(size: 16))
                            .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    }
                } else if let errorMessage = errorMessage {
                    LoadFailureFallbackView(
                        message: errorMessage,
                        onRetry: { Task { await loadWorkout() } },
                        onGoBack: { dismiss() }
                    )
                } else if let workout = workout {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(workout.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                            
                            Text(workout.description)
                                .font(.system(size: 16))
                                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                            
                            // Workout details
                            VStack(spacing: 12) {
                                DetailRow(icon: "clock", title: "Duration", value: "\(workout.duration) min")
                                DetailRow(icon: "flame", title: "Calories", value: "\(workout.caloriesBurned) cal")
                                DetailRow(icon: "chart.bar", title: "Difficulty", value: workout.difficulty.displayName)
                                DetailRow(icon: "tag", title: "Category", value: workout.category.displayName)
                            }
                            .padding()
                            .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(AppConstants.Design.cornerRadius)
                            
                            Button(action: {
                                showVideoPlayer = true
                            }) {
                                Text("Start Workout")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(AppConstants.Colors.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(AppConstants.Design.cornerRadius)
                            }
                        }
                        .padding()
                    }
                    .fullScreenCover(isPresented: $showVideoPlayer) {
                        VideoPlayerView(
                            workout: workout,
                            dayId: dayId,
                            planViewModel: viewModel
                        )
                        .onDisappear {
                            // Refresh plan when video player closes to update completion status
                            Task {
                                await viewModel.fetchUserPlan()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadWorkout()
            }
        }
    }
    
    private func loadWorkout() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let fetchedWorkout = try await WorkoutService.shared.fetchWorkout(id: workoutId) {
                workout = fetchedWorkout
            } else {
                errorMessage = "Workout not found"
            }
        } catch {
            errorMessage = "Failed to load workout. Please try again."
            print("Failed to fetch workout: \(error)")
        }
        
        isLoading = false
    }
}

struct RestDaySheet: View {
    let day: WorkoutDay
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppConstants.Colors.primary.opacity(0.7))
                    
                    Text("Rest Day")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                    
                    Text("Take a well-deserved break! Rest is an important part of your fitness journey.")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle(day.dayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppConstants.Colors.primary)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
        }
    }
}

#Preview {
    WorkoutPlanView()
}

