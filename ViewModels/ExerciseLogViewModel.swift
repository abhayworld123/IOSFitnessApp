import Foundation
import SwiftUI

@MainActor
class ExerciseLogViewModel: ObservableObject {
    @Published var savedSets: [ExerciseSet] = []
    @Published var currentReps: Int = 0
    @Published var currentWeight: Double = 0.0
    @Published var restTime: Int = 120
    @Published var note: String = ""
    @Published var savedLog: ExerciseLog?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    /// True when the initial Firestore load failed (save errors still use `errorMessage` only).
    @Published var initialLoadFailed: Bool = false
    @Published var selectedTab: LogTab = .sets
    
    private let exerciseLogService = ExerciseLogService.shared
    private let exercise: Exercise
    private let workout: Workout
    private let userId: String
    
    init(exercise: Exercise, workout: Workout, userId: String) {
        self.exercise = exercise
        self.workout = workout
        self.userId = userId
        self.restTime = exercise.restTime > 0 ? exercise.restTime : 120
    }
    
    // MARK: - Load Logs
    
    func loadLogs() async {
        isLoading = true
        errorMessage = nil
        initialLoadFailed = false
        
        do {
            let log = try await exerciseLogService.fetchExerciseLog(
                exerciseId: exercise.id,
                workoutId: workout.id,
                userId: userId
            )
            
            savedLog = log
            savedSets = log?.sets ?? []
        } catch {
            errorMessage = "Failed to load exercise logs: \(error.localizedDescription)"
            initialLoadFailed = true
        }
        
        isLoading = false
    }
    
    // MARK: - Counter Methods
    
    func incrementReps() {
        currentReps += 1
        HapticFeedback.impact()
    }
    
    func decrementReps() {
        if currentReps > 0 {
            currentReps -= 1
            HapticFeedback.impact()
        }
    }
    
    func updateReps(_ value: Int) {
        currentReps = max(0, value)
    }
    
    func validateRepsInput(_ text: String) -> Int? {
        guard let value = Int(text), value >= 0 else {
            return nil
        }
        return value
    }
    
    func incrementWeight(by amount: Double = 1.0) {
        currentWeight += amount
        currentWeight = round(currentWeight * 10) / 10 // Round to 1 decimal place
        HapticFeedback.impact()
    }
    
    func decrementWeight(by amount: Double = 1.0) {
        if currentWeight >= amount {
            currentWeight -= amount
            currentWeight = round(currentWeight * 10) / 10 // Round to 1 decimal place
            HapticFeedback.impact()
        } else {
            currentWeight = 0.0
            HapticFeedback.impact()
        }
    }
    
    func updateWeight(_ value: Double) {
        currentWeight = max(0.0, value)
        currentWeight = round(currentWeight * 10) / 10 // Round to 1 decimal place
    }
    
    func validateWeightInput(_ text: String) -> Double? {
        guard let value = Double(text), value >= 0 else {
            return nil
        }
        return round(value * 10) / 10 // Round to 1 decimal place
    }
    
    // MARK: - Rest Time and Note
    
    func updateRestTime(_ time: Int) {
        restTime = max(0, time)
    }
    
    func updateNote(_ noteText: String) {
        note = noteText
    }
    
    // MARK: - Set Management
    
    func addNewSet() {
        currentReps = 0
        currentWeight = 0.0
        note = ""
    }
    
    func editSet(_ set: ExerciseSet) {
        currentReps = set.reps
        currentWeight = set.weight
        note = set.note ?? ""
    }
    
    func deleteSet(_ setId: String) async {
        guard var log = savedLog else { return }
        
        log.sets.removeAll { $0.id == setId }
        savedSets = log.sets
        
        do {
            try await exerciseLogService.saveExerciseLog(log)
            await loadLogs() // Reload to get updated data
        } catch {
            errorMessage = "Failed to delete set: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Save Current Set
    
    func saveCurrentSet() async {
        guard currentReps > 0 && currentWeight > 0 else {
            errorMessage = "Please enter reps and weight before saving"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let newSet = ExerciseSet(
            reps: currentReps,
            weight: currentWeight,
            setNumber: savedSets.count + 1,
            note: note.isEmpty ? nil : note,
            completedAt: Date()
        )
        
        var log: ExerciseLog
        if let existingLog = savedLog {
            log = existingLog
            log.sets.append(newSet)
            log.restTime = restTime
            log.updatedAt = Date()
        } else {
            log = ExerciseLog(
                exerciseId: exercise.id,
                workoutId: workout.id,
                userId: userId,
                sets: [newSet],
                date: Date(),
                restTime: restTime
            )
        }
        
        do {
            try await exerciseLogService.saveExerciseLog(log)
            savedLog = log
            savedSets = log.sets
            
            // Reset form for next set
            addNewSet()
            
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to save set: \(error.localizedDescription)"
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Validation
    
    func validateAndSave() async {
        await saveCurrentSet()
    }
    
    var canSave: Bool {
        return currentReps > 0 && currentWeight > 0
    }
}
