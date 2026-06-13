import Foundation
import SwiftUI

@MainActor
class WorkoutPlanViewModel: ObservableObject {
    @Published var currentPlan: WorkoutPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// Only set when fetching an existing plan fails (generation errors keep using ``errorMessage``).
    @Published var planLoadError: String?
    @Published var generationProgress: Double = 0
    
    private let planService = WorkoutPlanService.shared
    private let authService = AuthService.shared
    
    var hasActivePlan: Bool {
        return currentPlan != nil
    }
    
    init() {
        // Don't fetch immediately - wait for auth to be ready
        // Call fetchUserPlan() explicitly when needed
    }
    
    // MARK: - Fetch Plan
    
    func fetchUserPlan() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else {
            planLoadError = nil
            errorMessage = nil
            currentPlan = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        planLoadError = nil
        
        do {
            currentPlan = try await planService.fetchUserPlan(userId: userId)
            if currentPlan == nil {
                errorMessage = nil
            }
        } catch {
            let msg = "Failed to load workout plan. Please try again."
            planLoadError = msg
            errorMessage = msg
            print("Error fetching plan: \(error.localizedDescription)")
            currentPlan = nil
        }
        
        isLoading = false
    }
    
    // MARK: - Generate Plan
    
    func generatePlan(
        goal: FitnessGoal,
        experienceLevel: DifficultyLevel,
        daysPerWeek: Int,
        durationMinutes: Int,
        equipment: EquipmentAvailability
    ) async {
        guard let userId = authService.getCurrentAuthUser()?.uid else {
            errorMessage = "Please sign in to generate a plan"
            return
        }
        
        isLoading = true
        errorMessage = nil
        generationProgress = 0
        
        // Deactivate current plan if exists
        if let existingPlan = currentPlan {
            do {
                try await planService.deactivatePlan(planId: existingPlan.id)
            } catch {
                print("Failed to deactivate existing plan: \(error.localizedDescription)")
            }
        }
        
        // Simulate progress
        generationProgress = 0.3
        
        do {
            let plan = try await planService.generatePlan(
                goal: goal,
                experienceLevel: experienceLevel,
                daysPerWeek: daysPerWeek,
                durationMinutes: durationMinutes,
                equipment: equipment,
                userId: userId
            )
            
            generationProgress = 0.7
            
            // Save plan
            try await planService.createPlan(plan)
            
            generationProgress = 1.0
            
            currentPlan = plan
            planLoadError = nil
            AnalyticsService.shared.trackPlanGenerated(goal: goal.displayName, daysPerWeek: daysPerWeek)
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to generate plan. Please try again."
            HapticFeedback.error()
            print("Error generating plan: \(error.localizedDescription)")
        }
        
        isLoading = false
        generationProgress = 0
    }
    
    // MARK: - Mark Workout Complete
    
    func markWorkoutComplete(dayId: String) async {
        guard let plan = currentPlan else { return }
        
        do {
            try await planService.markWorkoutComplete(planId: plan.id, dayId: dayId)
            await fetchUserPlan() // Refresh plan
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to mark workout as complete"
            HapticFeedback.error()
        }
    }
    
    // MARK: - Regenerate Plan
    
    func regeneratePlan() async {
        guard let plan = currentPlan,
              let userId = authService.getCurrentAuthUser()?.uid else {
            return
        }
        
        await generatePlan(
            goal: plan.goal,
            experienceLevel: .intermediate, // Default, could be stored in user profile
            daysPerWeek: plan.workoutsPerWeek,
            durationMinutes: 30, // Default, could be calculated from plan
            equipment: .basic // Default
        )
    }
}

