import Foundation
import SwiftUI

/// Filter chips on the exercise picker (Trakkit session builder).
enum ExerciseCatalogFilter: String, CaseIterable {
    case all = "All"
    case strength = "Strength"
    case cardio = "Cardio"
    case recovery = "Recovery"
    
    func matches(_ exercise: Exercise) -> Bool {
        switch self {
        case .all:
            return true
        case .recovery:
            return Self.isRecoveryStyle(exercise)
        case .cardio:
            let n = exercise.name.lowercased()
            return exercise.muscleGroups.contains(.cardio)
                || Self.cardioKeywords.contains { n.contains($0) }
        case .strength:
            guard !Self.isRecoveryStyle(exercise) else { return false }
            if exercise.muscleGroups == [.cardio] { return false }
            return true
        }
    }
    
    private static let cardioKeywords = ["run", "jump", "sprint", "burpee", "bike", "hiit", "cardio", "rowing"]
    
    private static func isRecoveryStyle(_ exercise: Exercise) -> Bool {
        let n = exercise.name.lowercased()
        let d = exercise.description.lowercased()
        if n.contains("stretch") || n.contains("mobility") || n.contains("yoga") { return true }
        if n.contains("flow") && (n.contains("thoracic") || n.contains("stretch") || d.contains("flow")) { return true }
        if d.contains("stretch") || d.contains("mobility") || d.contains("recovery") { return true }
        return false
    }
}

@MainActor
class CreateWorkoutViewModel: ObservableObject {
    @Published var workoutName: String = ""
    @Published var workoutDescription: String = ""
    /// Strength / Cardio / Yoga — drives `Workout.category` on save.
    @Published var selectedActivityCategory: WorkoutCategory = .strength
    /// Optional “Others” line merged into saved description.
    @Published var othersActivityNotes: String = ""
    @Published var scheduleWorkoutEnabled: Bool = true
    /// Mon=0 … Sun=6 (labels M T W T F S S).
    @Published var selectedScheduleWeekdayIndices: Set<Int> = [1]
    @Published var selectedExercises: Set<String> = []
    @Published var allExercises: [Exercise] = []
    @Published var filteredExercises: [Exercise] = []
    @Published var searchQuery: String = ""
    @Published var exerciseCatalogFilter: ExerciseCatalogFilter = .all
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
        
        allExercises = await workoutService.fetchAllExercisesMerged()
        applyFilters()
        
        if allExercises.isEmpty {
            errorMessage = "Failed to load exercises. Please try again."
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
    
    /// Minutes shown in session builder (same rule as workout duration estimate).
    var estimatedSessionMinutes: Int {
        max(1, selectedExercises.count * 3)
    }
    
    /// Selected exercises in catalog order (for thumbnail strip).
    var selectedExercisesInCatalogOrder: [Exercise] {
        allExercises.filter { selectedExercises.contains($0.id) }
    }
    
    // MARK: - Search & catalog filter
    
    func searchExercises(query: String) {
        searchQuery = query
        applyFilters()
    }
    
    func setExerciseCatalogFilter(_ filter: ExerciseCatalogFilter) {
        exerciseCatalogFilter = filter
        applyFilters()
    }
    
    private func applyFilters() {
        let searchFiltered: [Exercise]
        if searchQuery.isEmpty {
            searchFiltered = allExercises
        } else {
            let lowercasedQuery = searchQuery.lowercased()
            searchFiltered = allExercises.filter { exercise in
                exercise.name.lowercased().contains(lowercasedQuery) ||
                exercise.description.lowercased().contains(lowercasedQuery) ||
                exercise.muscleGroups.contains { $0.displayName.lowercased().contains(lowercasedQuery) }
            }
        }
        filteredExercises = searchFiltered.filter { exerciseCatalogFilter.matches($0) }
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
    
    func toggleScheduleWeekday(_ index: Int) {
        guard (0..<7).contains(index) else { return }
        if selectedScheduleWeekdayIndices.contains(index) {
            selectedScheduleWeekdayIndices.remove(index)
        } else {
            selectedScheduleWeekdayIndices.insert(index)
        }
    }
    
    // MARK: - Load Existing Workout
    
    func loadExistingWorkout(_ workout: Workout) {
        existingWorkout = workout
        workoutName = workout.title
        workoutDescription = workout.description
        selectedExercises = Set(workout.exercises)
        userId = workout.userId
        selectedActivityCategory = Self.displayCategory(from: workout.category)
        othersActivityNotes = ""
        scheduleWorkoutEnabled = true
        selectedScheduleWeekdayIndices = [1]
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
            description: mergedDescriptionForPersistence(),
            category: selectedActivityCategory,
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
        updatedWorkout.description = mergedDescriptionForPersistence()
        updatedWorkout.category = selectedActivityCategory
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
        selectedActivityCategory = .strength
        othersActivityNotes = ""
        scheduleWorkoutEnabled = true
        selectedScheduleWeekdayIndices = [1]
        selectedExercises.removeAll()
        searchQuery = ""
        exerciseCatalogFilter = .all
        applyFilters()
        existingWorkout = nil
    }
    
    /// Description passed to exercise selection / analytics (includes “Others”).
    func composedWorkoutDescriptionForFlow() -> String {
        mergedDescriptionForPersistence()
    }
    
    private func mergedDescriptionForPersistence() -> String {
        let base = workoutDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let other = othersActivityNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if other.isEmpty { return base }
        if base.isEmpty { return "Other focus: \(other)" }
        return base + "\n\nOther focus: \(other)"
    }
    
    private static func displayCategory(from category: WorkoutCategory) -> WorkoutCategory {
        switch category {
        case .cardio, .hiit:
            return .cardio
        case .yoga, .flexibility:
            return .yoga
        default:
            return .strength
        }
    }
}
