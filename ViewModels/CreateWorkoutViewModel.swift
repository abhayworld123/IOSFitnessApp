import Foundation
import SwiftUI

@MainActor
class CreateWorkoutViewModel: ObservableObject {
    @Published var workoutName: String = ""
    @Published var workoutDescription: String = ""
    @Published var selectedExercises: Set<String> = []
    @Published var allExercises: [Exercise] = []
    @Published var filteredExercises: [Exercise] = []
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let workoutService = WorkoutService.shared
    var userId: String?
    var existingWorkout: Workout?
    
    init() {
        Task {
            await fetchExercises()
        }
    }
    
    // MARK: - Fetch Exercises
    
    func fetchExercises() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try to load from JSON file first
            allExercises = try ExerciseDataService.loadExercisesFromJSON()
            filteredExercises = allExercises
        } catch {
            // Fallback to Firebase if JSON loading fails
            do {
                allExercises = try await workoutService.fetchAllExercises()
                filteredExercises = allExercises
            } catch {
                errorMessage = "Failed to load exercises. Please try again."
                print("Error fetching exercises: \(error.localizedDescription)")
                // Fallback to empty array if both fail
                allExercises = []
                filteredExercises = []
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Exercise Selection
    
    func toggleExerciseSelection(_ exerciseId: String) {
        if selectedExercises.contains(exerciseId) {
            selectedExercises.remove(exerciseId)
        } else {
            selectedExercises.insert(exerciseId)
        }
    }
    
    func isExerciseSelected(_ exerciseId: String) -> Bool {
        return selectedExercises.contains(exerciseId)
    }
    
    /// Catalog order; exercises in `selectedExercises` only.
    var selectedExercisesList: [Exercise] {
        allExercises.filter { selectedExercises.contains($0.id) }
    }
    
    /// Search-filtered exercises not yet selected (deduped vs top section).
    var pickerExercises: [Exercise] {
        filteredExercises.filter { !selectedExercises.contains($0.id) }
    }
    
    // MARK: - Search
    
    func searchExercises(query: String) {
        searchQuery = query
        applyFilters()
    }
    
    private func applyFilters() {
        if searchQuery.isEmpty {
            filteredExercises = allExercises
        } else {
            let lowercasedQuery = searchQuery.lowercased()
            filteredExercises = allExercises.filter { exercise in
                exercise.name.lowercased().contains(lowercasedQuery) ||
                exercise.description.lowercased().contains(lowercasedQuery) ||
                exercise.muscleGroups.contains { $0.displayName.lowercased().contains(lowercasedQuery) }
            }
        }
    }
    
    // MARK: - Validation
    
    func validateWorkoutName() -> Bool {
        return !workoutName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func canProceedToExerciseSelection() -> Bool {
        return validateWorkoutName()
    }
    
    func canSaveWorkout() -> Bool {
        return validateWorkoutName() && !selectedExercises.isEmpty
    }
    
    // MARK: - Load Existing Workout
    
    func loadExistingWorkout(_ workout: Workout) {
        existingWorkout = workout
        workoutName = workout.title
        workoutDescription = workout.description
        selectedExercises = Set(workout.exercises)
        userId = workout.userId
    }
    
    // MARK: - Create Workout
    
    func createWorkout() async throws -> Workout {
        guard canSaveWorkout() else {
            throw NSError(domain: "CreateWorkoutViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Workout name and at least one exercise are required"])
        }
        
        // If editing existing workout, update it instead
        if let existing = existingWorkout {
            return try await updateWorkout(existing)
        }
        
        let workout = Workout(
            title: workoutName.trimmingCharacters(in: .whitespaces),
            description: workoutDescription.trimmingCharacters(in: .whitespaces),
            category: .strength, // Default, could be determined from exercises
            difficulty: .intermediate, // Default, could be determined from exercises
            duration: calculateEstimatedDuration(),
            exercises: Array(selectedExercises),
            caloriesBurned: calculateEstimatedCalories(),
            userId: userId
        )
        
        try await workoutService.createWorkout(workout)
        return workout
    }
    
    // MARK: - Update Workout
    
    func updateWorkout(_ workout: Workout) async throws -> Workout {
        guard !selectedExercises.isEmpty else {
            throw NSError(domain: "CreateWorkoutViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "At least one exercise is required"])
        }
        
        var updatedWorkout = workout
        updatedWorkout.title = workoutName.trimmingCharacters(in: .whitespaces)
        updatedWorkout.description = workoutDescription.trimmingCharacters(in: .whitespaces)
        updatedWorkout.exercises = Array(selectedExercises)
        updatedWorkout.duration = calculateEstimatedDuration()
        updatedWorkout.caloriesBurned = calculateEstimatedCalories()
        updatedWorkout.updatedAt = Date()
        
        try await workoutService.updateWorkout(updatedWorkout)
        return updatedWorkout
    }
    
    // MARK: - Helper Methods
    
    private func calculateEstimatedDuration() -> Int {
        // Estimate 3 minutes per exercise (including rest time)
        return selectedExercises.count * 3
    }
    
    private func calculateEstimatedCalories() -> Int {
        // Rough estimate: 50 calories per exercise
        return selectedExercises.count * 50
    }
    
    // MARK: - Reset
    
    func reset() {
        workoutName = ""
        workoutDescription = ""
        selectedExercises.removeAll()
        searchQuery = ""
        filteredExercises = allExercises
        existingWorkout = nil
    }
}
