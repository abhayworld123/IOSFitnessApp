import Foundation
import FirebaseFirestore

@MainActor
class WorkoutPlanService: ObservableObject {
    static let shared = WorkoutPlanService()
    
    private let db = Firestore.firestore()
    private let workoutPlansCollection = "workoutPlans"
    private let workoutsCollection = "workouts"
    
    private init() {}
    
    // MARK: - Plan CRUD Operations
    
    func createPlan(_ plan: WorkoutPlan) async throws {
        // Ensure plan has userId
        guard !plan.userId.isEmpty else {
            throw NSError(domain: "WorkoutPlanService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Plan must have a userId"])
        }
        
        var data = try Firestore.Encoder().encode(plan)
        // Ensure timestamps are set
        data["createdAt"] = Timestamp(date: plan.createdAt)
        data["updatedAt"] = Timestamp(date: plan.updatedAt)
        if let startDate = plan.startDate {
            data["startDate"] = Timestamp(date: startDate)
        }
        
        // Save plan
        try await db.collection(workoutPlansCollection).document(plan.id).setData(data)
        
        // Update user's currentWorkoutPlanId
        try await db.collection("users").document(plan.userId).updateData([
            "currentWorkoutPlanId": plan.id,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func fetchUserPlan(userId: String) async throws -> WorkoutPlan? {
        guard !userId.isEmpty else {
            throw NSError(domain: "WorkoutPlanService", code: 1, userInfo: [NSLocalizedDescriptionKey: "userId cannot be empty"])
        }
        
        // First try to get plan from user's currentWorkoutPlanId
        let userDoc = try await db.collection("users").document(userId).getDocument()
        if let userData = userDoc.data(),
           let planId = userData["currentWorkoutPlanId"] as? String {
            let planDoc = try await db.collection(workoutPlansCollection).document(planId).getDocument()
            if let planData = planDoc.data(),
               let plan = try? Firestore.Decoder().decode(WorkoutPlan.self, from: planData),
               plan.isActive {
                return plan
            }
        }
        
        // Fallback: search for active plan by userId
        let snapshot = try await db.collection(workoutPlansCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        return try Firestore.Decoder().decode(WorkoutPlan.self, from: document.data())
    }
    
    func updatePlan(_ plan: WorkoutPlan) async throws {
        var data = try Firestore.Encoder().encode(plan)
        data["updatedAt"] = Timestamp(date: Date())
        try await db.collection(workoutPlansCollection).document(plan.id).updateData(data)
    }
    
    func deactivatePlan(planId: String) async throws {
        try await db.collection(workoutPlansCollection).document(planId).updateData([
            "isActive": false,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Plan Generation Algorithm
    
    func generatePlan(
        goal: FitnessGoal,
        experienceLevel: DifficultyLevel,
        daysPerWeek: Int,
        durationMinutes: Int,
        equipment: EquipmentAvailability,
        userId: String
    ) async throws -> WorkoutPlan {
        // Fetch available workouts
        let allWorkouts = try await fetchAvailableWorkouts()
        
        // Filter workouts based on criteria
        var filteredWorkouts = allWorkouts.filter { workout in
            // Match difficulty level
            if experienceLevel != .allLevels && workout.difficulty != experienceLevel && workout.difficulty != .allLevels {
                return false
            }
            
            // Match duration (within 10 minutes tolerance)
            if abs(workout.duration - durationMinutes) > 10 {
                return false
            }
            
            return true
        }
        
        // Prioritize workouts that match the goal
        filteredWorkouts.sort { workout1, workout2 in
            let score1 = workoutScore(workout1, goal: goal, experienceLevel: experienceLevel)
            let score2 = workoutScore(workout2, goal: goal, experienceLevel: experienceLevel)
            return score1 > score2
        }
        
        // Generate weekly schedule
        let workoutDays = generateWeeklySchedule(
            workouts: filteredWorkouts,
            daysPerWeek: daysPerWeek,
            goal: goal
        )
        
        // Create plan
        let plan = WorkoutPlan(
            name: "\(goal.displayName) Plan",
            goal: goal,
            durationWeeks: 4, // Default 4 weeks
            workoutsPerWeek: daysPerWeek,
            workouts: workoutDays,
            userId: userId,
            startDate: Date()
        )
        
        return plan
    }
    
    // MARK: - Helper Methods
    
    private func fetchAvailableWorkouts() async throws -> [Workout] {
        let snapshot = try await db.collection(workoutsCollection)
            .getDocuments()
        
        var workouts: [Workout] = []
        for document in snapshot.documents {
            if let workout = try? Firestore.Decoder().decode(Workout.self, from: document.data()) {
                workouts.append(workout)
            }
        }
        return workouts
    }
    
    private func workoutScore(_ workout: Workout, goal: FitnessGoal, experienceLevel: DifficultyLevel) -> Int {
        var score = 0
        
        // Goal matching
        switch goal {
        case .weightLoss:
            if workout.category == .cardio || workout.category == .hiit {
                score += 10
            }
        case .muscleGain:
            if workout.category == .strength {
                score += 10
            }
        case .flexibility:
            if workout.category == .yoga || workout.category == .flexibility {
                score += 10
            }
        case .endurance:
            if workout.category == .cardio || workout.category == .hiit {
                score += 10
            }
        }
        
        // Difficulty matching
        if workout.difficulty == experienceLevel {
            score += 5
        }
        
        // Calorie burn (for weight loss)
        if goal == .weightLoss {
            score += workout.caloriesBurned / 10
        }
        
        return score
    }
    
    private func generateWeeklySchedule(
        workouts: [Workout],
        daysPerWeek: Int,
        goal: FitnessGoal
    ) -> [WorkoutDay] {
        var schedule: [WorkoutDay] = []
        var workoutIndex = 0
        
        // Determine workout distribution based on goal
        let (strengthDays, cardioDays) = getWorkoutDistribution(goal: goal, daysPerWeek: daysPerWeek)
        
        // Create schedule for the week (Sunday = 0, Monday = 1, etc.)
        for day in 0..<7 {
            // Skip days if we've reached the target days per week
            let currentWorkoutCount = schedule.filter { !$0.isRestDay }.count
            if currentWorkoutCount >= daysPerWeek {
                schedule.append(WorkoutDay(dayOfWeek: day, isRestDay: true))
                continue
            }
            
            // Determine if this should be a strength or cardio day
            let strengthCount = schedule.filter { day in
                guard let workoutId = day.workoutId,
                      let workout = workouts.first(where: { $0.id == workoutId }),
                      workout.category == .strength else {
                    return false
                }
                return true
            }.count
            
            let cardioCount = schedule.filter { day in
                guard let workoutId = day.workoutId,
                      let workout = workouts.first(where: { $0.id == workoutId }),
                      (workout.category == .cardio || workout.category == .hiit) else {
                    return false
                }
                return true
            }.count
            
            // Select workout type
            let needsStrength = strengthCount < strengthDays
            let needsCardio = cardioCount < cardioDays
            
            var selectedWorkout: Workout?
            
            if needsStrength && needsCardio {
                // Alternate or prioritize based on day
                if day % 2 == 0 {
                    selectedWorkout = workouts.first { $0.category == .strength }
                } else {
                    selectedWorkout = workouts.first { $0.category == .cardio || $0.category == .hiit }
                }
            } else if needsStrength {
                selectedWorkout = workouts.first { $0.category == .strength }
            } else if needsCardio {
                selectedWorkout = workouts.first { $0.category == .cardio || $0.category == .hiit }
            }
            
            // If no specific type needed, pick any workout
            if selectedWorkout == nil && workoutIndex < workouts.count {
                selectedWorkout = workouts[workoutIndex]
                workoutIndex += 1
            }
            
            if let workout = selectedWorkout {
                schedule.append(WorkoutDay(dayOfWeek: day, workoutId: workout.id))
            } else {
                schedule.append(WorkoutDay(dayOfWeek: day, isRestDay: true))
            }
        }
        
        return schedule
    }
    
    private func getWorkoutDistribution(goal: FitnessGoal, daysPerWeek: Int) -> (strength: Int, cardio: Int) {
        switch goal {
        case .weightLoss:
            // More cardio for weight loss
            return (strength: max(1, daysPerWeek / 3), cardio: daysPerWeek - max(1, daysPerWeek / 3))
        case .muscleGain:
            // More strength for muscle gain
            return (strength: max(1, daysPerWeek * 2 / 3), cardio: daysPerWeek - max(1, daysPerWeek * 2 / 3))
        case .flexibility:
            // Mix of yoga/flexibility
            return (strength: max(1, daysPerWeek / 2), cardio: daysPerWeek - max(1, daysPerWeek / 2))
        case .endurance:
            // More cardio for endurance
            return (strength: max(1, daysPerWeek / 3), cardio: daysPerWeek - max(1, daysPerWeek / 3))
        }
    }
    
    // MARK: - Progress Tracking
    
    func markWorkoutComplete(planId: String, dayId: String) async throws {
        let planRef = db.collection(workoutPlansCollection).document(planId)
        let planDoc = try await planRef.getDocument()
        
        guard var plan = try? Firestore.Decoder().decode(WorkoutPlan.self, from: planDoc.data() ?? [:]) else {
            throw NSError(domain: "WorkoutPlanService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode plan"])
        }
        
        // Update the specific day
        if let index = plan.workouts.firstIndex(where: { $0.id == dayId }) {
            plan.workouts[index].completed = true
            plan.workouts[index].completedDate = Date()
        }
        
        try await updatePlan(plan)
    }
}

// MARK: - Equipment Availability
enum EquipmentAvailability: String, Codable, CaseIterable {
    case none = "none"
    case basic = "basic"
    case fullGym = "fullGym"
    
    var displayName: String {
        switch self {
        case .none:
            return "No Equipment"
        case .basic:
            return "Basic (Dumbbells, Mat)"
        case .fullGym:
            return "Full Gym"
        }
    }
}

