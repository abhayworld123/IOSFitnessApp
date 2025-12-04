import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isGridView = true
    @State private var showPaywall = false
    @State private var selectedWorkout: Workout?
    @State private var showDataSeeding = false
    
    var isPremium: Bool {
        authViewModel.currentUser?.subscriptionStatus == .premium
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Featured Workouts Carousel
                        if !viewModel.workouts.isEmpty {
                            featuredWorkoutsSection
                        }
                        
                        // Search Bar
                        searchBar
                        
                        // Category Filters
                        categoryFilters
                        
                        // Workouts Grid/List
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.filteredWorkouts.isEmpty {
                            emptyStateView
                        } else {
                            workoutsSection
                        }
                    }
                    .padding(.top, 8)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                AnalyticsService.shared.trackScreenView("Home", screenClass: "HomeView")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Development: Seed data button (remove in production)
                    Button(action: {
                        showDataSeeding = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(AppConstants.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isGridView.toggle()
                        HapticFeedback.impact()
                    }) {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .foregroundColor(AppConstants.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showDataSeeding) {
                DataSeedingView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(authViewModel)
            }
            .fullScreenCover(item: $selectedWorkout) { workout in
                if workout.isPremium && !isPremium {
                    // Show paywall instead
                    PaywallView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            selectedWorkout = nil
                        }
                } else {
                    VideoPlayerView(workout: workout)
                }
            }
            .onAppear {
                if viewModel.workouts.isEmpty {
                    Task {
                        await viewModel.fetchWorkouts()
                    }
                }
            }
        }
    }
    
    // MARK: - Featured Workouts Section
    private var featuredWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(viewModel.workouts.prefix(5))) { workout in
                        FeaturedWorkoutCard(workout: workout, isPremium: isPremium) {
                            handleWorkoutTap(workout)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            
            TextField("Search workouts...", text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                .onChange(of: viewModel.searchQuery) { newValue in
                    viewModel.searchWorkouts(query: newValue)
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                    viewModel.searchWorkouts(query: "")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                }
            }
        }
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Category Filters
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WorkoutCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        category: category,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.filterWorkouts(by: category)
                        HapticFeedback.impact(style: .light)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Workouts Section
    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Workouts")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
                
                Text("\(viewModel.filteredWorkouts.count) workouts")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            .padding(.horizontal, 20)
            
            if isGridView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(viewModel.filteredWorkouts) { workout in
                        WorkoutCardView(
                            workout: workout,
                            isPremium: isPremium,
                            onTap: {
                                handleWorkoutTap(workout)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredWorkouts) { workout in
                        WorkoutCardView(
                            workout: workout,
                            isPremium: isPremium,
                            onTap: {
                                handleWorkoutTap(workout)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading workouts...")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.5))
            
            Text("No workouts found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            Text("Try adjusting your filters or search query")
                .font(.system(size: 14))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
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

// MARK: - Featured Workout Card
struct FeaturedWorkoutCard: View {
    let workout: Workout
    let isPremium: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                if let thumbnailURL = workout.thumbnailURL, !thumbnailURL.isEmpty {
                    AsyncImage(url: URL(string: thumbnailURL)) { phase in
                        switch phase {
                        case .empty:
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
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
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
                        @unknown default:
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
                        }
                    }
                    .frame(width: 280, height: 180)
                    .clipped()
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
                        .frame(width: 280, height: 180)
                }
                
                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    if workout.isPremium && !isPremium {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                            Text("Premium")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppConstants.Colors.primary)
                        .cornerRadius(8)
                    }
                    
                    Text(workout.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack {
                        Label("\(workout.duration) min", systemImage: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
            }
            .frame(width: 280, height: 180)
            .cornerRadius(AppConstants.Design.cornerRadius)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let category: WorkoutCategory
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                AppConstants.Colors.primary :
                AppConstants.Colors.cardBackground(colorScheme: colorScheme)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}

