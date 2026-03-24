import SwiftUI

struct VideoLibraryView: View {
    @StateObject private var viewModel = VideoLibraryViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedWorkout: Workout?
    @State private var showPaywall = false
    
    var isPremium: Bool {
        authViewModel.currentUser?.subscriptionStatus == .premium
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(hex: "#F5F5F7")
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.workouts.isEmpty {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Bar
                            searchBar
                            
                            // Category Filters
                            categoryFilters
                            
                            // Difficulty Filter
                            difficultyFilter
                            
                            // View Toggle
                            viewToggle
                            
                            // Workouts Grid/List
                            if viewModel.filteredWorkouts.isEmpty {
                                emptyStateView
                            } else {
                                workoutsSection
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Videos")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh(userId: authViewModel.currentUser?.id)
            }
            .onAppear {
                AnalyticsService.shared.trackScreenView("VideoLibrary", screenClass: "VideoLibraryView")
                if viewModel.workouts.isEmpty {
                    Task {
                        await viewModel.fetchWorkouts(userId: authViewModel.currentUser?.id)
                    }
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
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search workouts...", text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: viewModel.searchQuery) { newValue in
                    viewModel.searchWorkouts(query: newValue)
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                    viewModel.searchWorkouts(query: "")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Category Filters
    
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WorkoutCategory.allCases, id: \.self) { category in
                    Button(action: {
                        viewModel.filterWorkouts(by: category)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                            
                            Text(category.displayName)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedCategory == category
                                ? Color(hex: "#FF9500")
                                : Color.white
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Difficulty Filter
    
    private var difficultyFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.filterWorkouts(by: nil)
                }) {
                    Text("All Levels")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.selectedDifficulty == nil ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedDifficulty == nil
                                ? Color(hex: "#FF9500")
                                : Color.white
                        )
                        .cornerRadius(20)
                }
                
                ForEach([DifficultyLevel.beginner, .intermediate, .advanced], id: \.self) { difficulty in
                    Button(action: {
                        viewModel.filterWorkouts(by: difficulty)
                    }) {
                        Text(difficulty.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.selectedDifficulty == difficulty ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedDifficulty == difficulty
                                    ? Color(hex: difficulty.color)
                                    : Color.white
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - View Toggle
    
    private var viewToggle: some View {
        HStack {
            Text("\(viewModel.filteredWorkouts.count) workouts")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Image(systemName: "list.bullet")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#FF9500"))
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Workouts Section
    
    private var workoutsSection: some View {
        Group {
            if viewModel.isGridView {
                gridView
            } else {
                listView
            }
        }
    }
    
    private var gridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(viewModel.filteredWorkouts) { workout in
                WorkoutCardView(
                    workout: workout,
                    isPremium: isPremium
                ) {
                    handleWorkoutTap(workout)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var listView: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredWorkouts) { workout in
                WorkoutCardView(
                    workout: workout,
                    isPremium: isPremium
                ) {
                    handleWorkoutTap(workout)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Workouts Found")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Try adjusting your filters or search query.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading workouts...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.top, 16)
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
}

#Preview {
    VideoLibraryView()
        .environmentObject(AuthViewModel())
}
