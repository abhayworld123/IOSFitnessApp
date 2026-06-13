import Foundation
import SwiftUI

/// One row in the in-session log grid (weight/reps as text for “--” placeholders).
struct SessionLogSet: Identifiable, Equatable {
    let id: String
    var setNumber: Int
    var weightText: String
    var repsText: String
    var completed: Bool
    
    init(
        id: String = UUID().uuidString,
        setNumber: Int,
        weightText: String = "",
        repsText: String = "",
        completed: Bool = false
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weightText = weightText
        self.repsText = repsText
        self.completed = completed
    }
    
    var displayWeight: String {
        weightText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "--" : weightText
    }
    
    var displayReps: String {
        repsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "--" : repsText
    }
}

struct SessionExerciseLogState: Identifiable {
    let exercise: Exercise
    var sets: [SessionLogSet]
    var id: String { exercise.id }
}

@MainActor
final class WorkoutSessionLogViewModel: ObservableObject {
    let workout: Workout
    let userId: String
    
    @Published var exercisesState: [SessionExerciseLogState]
    @Published var suggestedPlansEnabled: Bool
    @Published var restSeconds: Int
    @Published var expandedExerciseId: String?
    @Published var isSaving = false
    @Published var errorMessage: String?
    /// Elapsed active workout time (excludes paused intervals), updated every second while running.
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var isSessionPaused: Bool = false
    
    /// Full-screen rest countdown after marking a set complete.
    @Published private(set) var restOverlayPresented: Bool = false
    @Published private(set) var restRemainingSeconds: Int = 0
    /// Duration snapshot when the current countdown started (for ring progress).
    @Published private(set) var restCountdownTotalSeconds: Int = 1
    @Published private(set) var restCaption: String = "NEXT SET IN"
    @Published var restHydrationCardVisible: Bool = true
    
    static let restOptions = [30, 60, 90, 120]
    
    private let logService = ExerciseLogService.shared
    
    private var sessionStartTime: Date?
    private var pauseStartTime: Date?
    /// Sum of completed pause intervals (time spent paused).
    private var accumulatedPausedTime: TimeInterval = 0
    private var tickTimer: Timer?
    private var restCountdownTimer: Timer?
    
    init(workout: Workout, exercises: [Exercise], userId: String, suggestedPlansDefault: Bool = true) {
        self.workout = workout
        self.userId = userId
        self.suggestedPlansEnabled = suggestedPlansDefault
        self.restSeconds = 90
        self.exercisesState = exercises.map { ex in
            SessionExerciseLogState(
                exercise: ex,
                sets: Self.initialSets(for: ex, aiSuggested: suggestedPlansDefault)
            )
        }
        self.expandedExerciseId = exercises.first?.id
    }
    
    // MARK: - Session duration timer
    
    /// Call when the session log screen appears (after “Start Session”). Starts counting immediately.
    func startSessionTimerIfNeeded() {
        if sessionStartTime == nil {
            sessionStartTime = Date()
            accumulatedPausedTime = 0
            pauseStartTime = nil
            isSessionPaused = false
            elapsedSeconds = 0
        }
        scheduleTickTimerIfRunning()
        refreshElapsed()
    }
    
    /// Stop updates (e.g. when leaving the screen or after ending the session).
    func stopSessionTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
        invalidateRestCountdownTimer()
        restOverlayPresented = false
        refreshElapsed()
    }
    
    func toggleSessionPause() {
        if isSessionPaused {
            if let p = pauseStartTime {
                accumulatedPausedTime += Date().timeIntervalSince(p)
                pauseStartTime = nil
            }
            isSessionPaused = false
            scheduleTickTimerIfRunning()
            refreshElapsed()
        } else {
            pauseStartTime = Date()
            isSessionPaused = true
            tickTimer?.invalidate()
            tickTimer = nil
            refreshElapsed()
        }
    }
    
    var sessionDurationFormatted: String {
        let s = max(0, elapsedSeconds)
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d min", m, r)
    }
    
    private func scheduleTickTimerIfRunning() {
        guard !isSessionPaused else { return }
        tickTimer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshElapsed()
            }
        }
        tickTimer = t
        RunLoop.main.add(t, forMode: .common)
    }
    
    private func refreshElapsed() {
        elapsedSeconds = Int(floor(currentElapsedInterval()))
    }
    
    private func currentElapsedInterval() -> TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        let end: Date = pauseStartTime ?? Date()
        return max(0, end.timeIntervalSince(start) - accumulatedPausedTime)
    }
    
    private static func initialSets(for exercise: Exercise, aiSuggested: Bool) -> [SessionLogSet] {
        if aiSuggested {
            let reps = exercise.reps ?? 12
            let baseWeight = max(20, (exercise.sets ?? 3) * 5 + 25)
            return (1...3).map { i in
                let w = baseWeight + (i - 1) * 5
                return SessionLogSet(
                    setNumber: i,
                    weightText: "\(w)",
                    repsText: "\(reps)",
                    completed: i == 1
                )
            }
        }
        return [
            SessionLogSet(setNumber: 1, weightText: "", repsText: "", completed: false)
        ]
    }
    
    func setSuggestedPlansEnabled(_ enabled: Bool) {
        suggestedPlansEnabled = enabled
        exercisesState = exercisesState.map { st in
            SessionExerciseLogState(
                exercise: st.exercise,
                sets: Self.initialSets(for: st.exercise, aiSuggested: enabled)
            )
        }
    }
    
    func setRestSeconds(_ value: Int) {
        restSeconds = value
    }
    
    func expandExercise(_ id: String?) {
        expandedExerciseId = id
    }
    
    func toggleExerciseExpanded(_ id: String) {
        expandedExerciseId = (expandedExerciseId == id) ? nil : id
    }
    
    func addSet(forExerciseId exerciseId: String) {
        guard let idx = exercisesState.firstIndex(where: { $0.exercise.id == exerciseId }) else { return }
        var st = exercisesState[idx]
        let next = (st.sets.map(\.setNumber).max() ?? 0) + 1
        st.sets.append(SessionLogSet(setNumber: next, weightText: "", repsText: "", completed: false))
        exercisesState[idx] = st
    }
    
    func updateSetWeight(exerciseId: String, setId: String, text: String) {
        guard let eIdx = exercisesState.firstIndex(where: { $0.exercise.id == exerciseId }),
              let sIdx = exercisesState[eIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        var st = exercisesState[eIdx]
        st.sets[sIdx].weightText = text
        exercisesState[eIdx] = st
    }
    
    func updateSetReps(exerciseId: String, setId: String, text: String) {
        guard let eIdx = exercisesState.firstIndex(where: { $0.exercise.id == exerciseId }),
              let sIdx = exercisesState[eIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        var st = exercisesState[eIdx]
        st.sets[sIdx].repsText = text
        exercisesState[eIdx] = st
    }
    
    func toggleSetCompleted(exerciseId: String, setId: String) {
        guard let eIdx = exercisesState.firstIndex(where: { $0.exercise.id == exerciseId }),
              let sIdx = exercisesState[eIdx].sets.firstIndex(where: { $0.id == setId }) else { return }
        var st = exercisesState[eIdx]
        let wasCompleted = st.sets[sIdx].completed
        st.sets[sIdx].completed.toggle()
        let nowCompleted = st.sets[sIdx].completed
        exercisesState[eIdx] = st
        
        if nowCompleted && !wasCompleted {
            beginRestCountdown(exerciseId: exerciseId, completedSetIndex: sIdx)
        }
    }
    
    func dismissRestOverlay() {
        invalidateRestCountdownTimer()
        restOverlayPresented = false
        restHydrationCardVisible = true
    }
    
    func dismissRestHydrationCardOnly() {
        restHydrationCardVisible = false
    }
    
    /// Progress 0…1 for the orange ring (elapsed portion of rest).
    var restElapsedProgress: CGFloat {
        let total = max(1, restCountdownTotalSeconds)
        let elapsed = total - max(0, restRemainingSeconds)
        return CGFloat(Double(elapsed) / Double(total))
    }
    
    private func invalidateRestCountdownTimer() {
        restCountdownTimer?.invalidate()
        restCountdownTimer = nil
    }
    
    private func beginRestCountdown(exerciseId: String, completedSetIndex: Int) {
        invalidateRestCountdownTimer()
        
        let total = max(1, restSeconds)
        restCountdownTotalSeconds = total
        restRemainingSeconds = total
        
        if let eIdx = exercisesState.firstIndex(where: { $0.exercise.id == exerciseId }) {
            let setCount = exercisesState[eIdx].sets.count
            let isLastSetRow = completedSetIndex >= setCount - 1
            restCaption = isLastSetRow ? "NEXT EXERCISE IN" : "NEXT SET IN"
        } else {
            restCaption = "NEXT SET IN"
        }
        
        restHydrationCardVisible = true
        restOverlayPresented = true
        
        restCountdownTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                guard self.restOverlayPresented else { return }
                guard !self.isSessionPaused else { return }
                
                if self.restRemainingSeconds > 1 {
                    self.restRemainingSeconds -= 1
                } else {
                    self.restRemainingSeconds = 0
                    HapticFeedback.success()
                    self.dismissRestOverlay()
                }
            }
        }
        if let t = restCountdownTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }
    
    /// Persists one merged log per exercise (sets with valid weight + reps).
    func commitSession() async throws {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        for state in exercisesState {
            let built = buildExerciseSets(from: state)
            guard !built.isEmpty else { continue }
            let log = ExerciseLog(
                exerciseId: state.exercise.id,
                workoutId: workout.id,
                userId: userId,
                sets: built,
                date: Date(),
                restTime: restSeconds
            )
            try await logService.saveExerciseLog(log)
        }
    }
    
    private func buildExerciseSets(from state: SessionExerciseLogState) -> [ExerciseSet] {
        state.sets.compactMap { row in
            let wStr = row.weightText.trimmingCharacters(in: .whitespacesAndNewlines)
            let rStr = row.repsText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let w = Double(wStr), w > 0,
                  let r = Int(rStr), r > 0 else { return nil }
            return ExerciseSet(
                reps: r,
                weight: w,
                setNumber: row.setNumber,
                note: nil,
                completedAt: row.completed ? Date() : nil
            )
        }
    }
}
