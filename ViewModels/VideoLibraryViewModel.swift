import Foundation
import SwiftUI

@MainActor
class VideoLibraryViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var filteredWorkouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: WorkoutCategory = .all
    @Published var searchQuery: String = ""
    @Published var selectedDifficulty: DifficultyLevel? = nil
    @Published var isGridView = false
    
    private let workoutService = WorkoutService.shared
    
    init() {}
    
    // MARK: - Fetch Workouts (templates + current user's workouts)
    
    func fetchWorkouts(userId: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var all: [Workout] = try await workoutService.fetchTemplateWorkouts()
            if let userId = userId, !userId.isEmpty {
                let userWorkouts = try await workoutService.fetchUserWorkouts(userId: userId)
                let templateIds = Set(all.map(\.id))
                all = all + userWorkouts.filter { !templateIds.contains($0.id) }
            }
            workouts = all
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
    
    func searchWorkouts(query: String) {
        searchQuery = query
        applyFilters()
    }
    
    func toggleViewMode() {
        isGridView.toggle()
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
        
        // Apply search query
        if !searchQuery.isEmpty {
            filtered = workoutService.searchWorkouts(filtered, query: searchQuery)
        }
        
        filteredWorkouts = filtered
    }
    
    // MARK: - Refresh
    
    func refresh(userId: String? = nil) async {
        await fetchWorkouts(userId: userId)
    }
}
