import Foundation

enum AIWorkoutPlanPhase: Equatable {
    case askBodyPart
    case generating(MuscleGroup)
    case error(String)
}

extension MuscleGroup {
    /// Body parts offered in the AI plan picker (excludes cardio).
    static var aiPlanOptions: [MuscleGroup] {
        [.back, .legs, .chest, .shoulders, .arms, .core, .fullBody]
    }
}

@MainActor
final class AIWorkoutPlanViewModel: ObservableObject {
    @Published private(set) var phase: AIWorkoutPlanPhase = .askBodyPart
    @Published private(set) var savedWorkout: Workout?

    var isAPIConfigured: Bool { ExerciseAPIConfiguration.isConfigured }

    private let workoutService = WorkoutService.shared

    func reset() {
        phase = .askBodyPart
        savedWorkout = nil
    }

    func selectBodyPart(_ group: MuscleGroup, userName: String?, userId: String?) async {
        guard isAPIConfigured else {
            phase = .error("Exercise API URL is not configured.")
            return
        }
        guard let userId, !userId.isEmpty else {
            phase = .error("Please sign in to generate a workout plan.")
            return
        }

        phase = .generating(group)
        do {
            let plan = try await CoachAPIService.shared.generateWorkout(
                bodyPart: group,
                userName: userName
            )
            let workout = Workout(
                title: plan.title,
                description: plan.description.isEmpty
                    ? "AI-generated \(group.displayName.lowercased()) session."
                    : plan.description,
                category: .strength,
                difficulty: .intermediate,
                duration: max(15, plan.exerciseIds.count * 3),
                exercises: plan.exerciseIds,
                caloriesBurned: plan.exerciseIds.count * 40,
                userId: userId
            )
            try await workoutService.createWorkout(workout)
            savedWorkout = workout
            NotificationCenter.default.post(name: NSNotification.Name("WorkoutCreated"), object: nil)
        } catch let e as CoachAPIError {
            phase = .error(e.localizedDescription ?? "Could not generate plan.")
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func dismissError() {
        phase = .askBodyPart
    }
}
