import Foundation
import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var filteredWorkouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: WorkoutCategory = .all
    @Published var searchQuery: String = ""
    @Published var selectedDifficulty: DifficultyLevel? = nil
    @Published var showOnlyFree: Bool = false
    
    private let workoutService = WorkoutService.shared
    private let authService = AuthService.shared
    
    var isPremium: Bool {
        return authService.currentUser?.subscriptionStatus == .premium
    }
    
    init() {
        Task {
            await fetchWorkouts()
        }
    }
    
    // MARK: - Fetch Workouts
    func fetchWorkouts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            workouts = try await workoutService.fetchWorkouts()
            applyFilters()
        } catch {
            errorMessage = "Failed to load workouts. Please try again."
            print("Error fetching workouts: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering
    func filterWorkouts(by category: WorkoutCategory) {
        selectedCategory = category
        applyFilters()
    }
    
    func filterWorkouts(by difficulty: DifficultyLevel?) {
        selectedDifficulty = difficulty
        applyFilters()
    }
    
    func toggleFreeOnly() {
        showOnlyFree.toggle()
        applyFilters()
    }
    
    func searchWorkouts(query: String) {
        searchQuery = query
        applyFilters()
    }
    
    private func applyFilters() {
        var filtered = workouts
        
        // Apply category filter
        if selectedCategory != .all {
            filtered = workoutService.filterWorkouts(filtered, by: selectedCategory)
        }
        
        // Apply difficulty filter
        if let difficulty = selectedDifficulty {
            filtered = workoutService.filterWorkouts(filtered, by: difficulty)
        }
        
        // Apply premium filter
        if showOnlyFree {
            filtered = workoutService.filterWorkouts(filtered, isPremium: false)
        }
        
        // Apply search query
        if !searchQuery.isEmpty {
            filtered = workoutService.searchWorkouts(filtered, query: searchQuery)
        }
        
        filteredWorkouts = filtered
    }
    
    // MARK: - Premium Access Check
    func canAccessWorkout(_ workout: Workout) -> Bool {
        if !workout.isPremium {
            return true
        }
        return isPremium
    }
    
    func checkPremiumAccess(for workout: Workout) -> Bool {
        return canAccessWorkout(workout)
    }
    
    // MARK: - Refresh
    func refresh() async {
        await fetchWorkouts()
    }
    
    // MARK: - Seed Data (for development)
    func seedSampleData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await workoutService.seedSampleWorkouts()
            await fetchWorkouts()
        } catch {
            errorMessage = "Failed to seed sample data. It may already exist."
            print("Error seeding data: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

