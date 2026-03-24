import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class DashboardViewModel2: ObservableObject {
    @Published var streakData: StreakData
    @Published var dailyMetrics: DailyMetrics
    @Published var howToWorkouts: [Workout] = []
    @Published var userWorkouts: [Workout] = []
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let workoutService = WorkoutService.shared
    private let waterService = WaterTrackingService.shared
    private let dailyStatsService = DailyStatsService.shared
    private let authService = AuthService.shared
    
    let workoutActions: [WorkoutQuickAction] = [
        WorkoutQuickAction(
            title: "New Workout",
            subtitle: "eg: Upper body, Push plan, Leg day",
            iconName: "plus",
            iconColor: Color(hex: "#FF9500"),
            action: .newWorkout
        ),
        WorkoutQuickAction(
            title: "New Custom Plan..",
            subtitle: nil,
            iconName: "sparkles",
            iconColor: Color(hex: "#AF52DE"),
            action: .customPlan
        )
    ]
    
    init() {
        // Initialize with mock data
        self.streakData = DashboardViewModel2.generateMockStreakData()
        self.dailyMetrics = DashboardViewModel2.generateMockDailyMetrics()
    }
    
    // MARK: - Fetch Data
    
    func fetchDashboardData(userId: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        if let userId = userId, !userId.isEmpty {
            await fetchUserSpecificData(userId: userId)
        } else {
            streakData = DashboardViewModel2.generateMockStreakData()
            dailyMetrics = DashboardViewModel2.generateMockDailyMetrics()
        }
        
        await fetchHowToWorkouts()
        await fetchExercisesFromFirebase()
        
        if let userId = userId {
            await fetchUserWorkouts(userId: userId)
        }
        
        isLoading = false
    }
    
    /// Fetches streak, daily metrics (water, weight) from Firebase for the given user.
    /// Uses empty baseline for new users so we show "Start tracking..." instead of fake defaults.
    private func fetchUserSpecificData(userId: String) async {
        var metrics = DashboardViewModel2.generateEmptyDailyMetrics()
        var streak = buildStreakData(completionDates: [])
        
        do {
            // 1. Today's water intake
            if let todayIntake = try? await waterService.fetchTodayIntake(userId: userId, date: Date()) {
                metrics.water.current = todayIntake.glassesConsumed
                metrics.water.goal = todayIntake.goal
            }
            
            // 2. User profile (weight)
            let userDoc = try? await db.collection("users").document(userId).getDocument()
            if let data = userDoc?.data(), let weight = data["weight"] as? Double {
                metrics.weight.current = weight
                if let target = data["targetWeight"] as? Double {
                    metrics.weight.target = target
                    metrics.weight.lost = max(0, metrics.weight.current - target)
                }
            }
            
            // 2b. Today's daily stats (steps, sleep)
            if let todayStats = try? await dailyStatsService.fetchDailyStats(userId: userId, date: Date()) {
                metrics.steps.current = todayStats.steps
                metrics.steps.goal = todayStats.stepsGoal
                metrics.sleep.current = todayStats.sleep
                metrics.sleep.goal = todayStats.sleepGoal
                if let w = todayStats.weight {
                    metrics.weight.current = w
                }
            }
            
            // 3. Completion dates from userProgress for streak
            let snapshot = try? await db.collection("userProgress")
                .document(userId)
                .collection("completedWorkouts")
                .getDocuments()
            
            var completionDates: [Date] = []
            for doc in snapshot?.documents ?? [] {
                let d = doc.data()
                if let completed = d["completed"] as? Bool, completed,
                   let date = (d["completedDate"] as? Timestamp)?.dateValue() ?? (d["lastUpdated"] as? Timestamp)?.dateValue() {
                    completionDates.append(date)
                }
            }
            streak = buildStreakData(completionDates: completionDates)
        }
        
        dailyMetrics = metrics
        streakData = streak
    }
    
    /// Builds StreakData from workout completion dates (same logic as ProfileViewModel).
    private func buildStreakData(completionDates: [Date]) -> StreakData {
        let calendar = Calendar.current
        let today = Date()
        let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
        let completionDaySet = Set(completionDates.map { calendar.startOfDay(for: $0) })
        
        var activities: [DayActivity] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i - 6, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayName = dayNames[i]
            let isCompleted = completionDaySet.contains(dayStart)
            activities.append(DayActivity(dayName: dayName, date: date, isCompleted: isCompleted))
        }
        
        let currentStreak = calculateStreak(from: completionDates)
        return StreakData(weeklyActivities: activities, currentStreak: currentStreak)
    }
    
    private func calculateStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sortedDates = dates.sorted(by: >)
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        for date in sortedDates {
            let dayStart = calendar.startOfDay(for: date)
            if calendar.isDate(dayStart, inSameDayAs: currentDate) {
                continue
            } else if calendar.date(byAdding: .day, value: -1, to: currentDate) == dayStart {
                streak += 1
                currentDate = dayStart
            } else {
                break
            }
        }
        let todayStart = calendar.startOfDay(for: Date())
        if let mostRecent = sortedDates.first,
           calendar.isDate(calendar.startOfDay(for: mostRecent), inSameDayAs: todayStart) {
            streak += 1
        }
        return streak
    }
    
    func fetchHowToWorkouts() async {
        if let workouts = try? await workoutService.fetchTemplateWorkouts() {
            howToWorkouts = Array(workouts.prefix(5))
        }
    }
    
    func fetchUserWorkouts(userId: String?) async {
        guard let userId = userId, !userId.isEmpty else {
            userWorkouts = []
            return
        }
        
        do {
            userWorkouts = try await workoutService.fetchUserWorkouts(userId: userId)
        } catch {
            print("Error fetching user workouts: \(error.localizedDescription)")
            userWorkouts = []
        }
    }
    
    func fetchExercisesFromFirebase() async {
        do {
            exercises = try await workoutService.fetchAllExercises()
        } catch {
            print("Error fetching exercises from Firebase: \(error.localizedDescription)")
            exercises = []
        }
    }
    
    // MARK: - Update Methods
    
    func toggleDayCompletion(dayId: String) {
        if let index = streakData.weeklyActivities.firstIndex(where: { $0.id == dayId }) {
            streakData.weeklyActivities[index].isCompleted.toggle()
            // TODO: Save to Firebase
        }
    }
    
    func updateWater(glasses: Int) {
        dailyMetrics.water.current = max(0, dailyMetrics.water.current + glasses)
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        Task {
            let today = Date()
            if var intake = try? await waterService.fetchTodayIntake(userId: userId, date: today) {
                intake.glassesConsumed = dailyMetrics.water.current
                intake.updatedAt = Date()
                try? await waterService.saveIntake(intake)
            } else {
                let intake = WaterIntakeRecord(
                    userId: userId,
                    date: today,
                    glassesConsumed: dailyMetrics.water.current,
                    goal: dailyMetrics.water.goal
                )
                try? await waterService.saveIntake(intake)
            }
        }
    }
    
    func updateSteps(steps: Int) {
        dailyMetrics.steps.current = max(0, steps)
        persistDailyStats(steps: dailyMetrics.steps.current, stepsGoal: dailyMetrics.steps.goal)
    }
    
    func updateSleep(hours: Double) {
        dailyMetrics.sleep.current = max(0, hours)
        persistDailyStats(sleep: dailyMetrics.sleep.current, sleepGoal: dailyMetrics.sleep.goal)
    }
    
    func updateWeight(weight: Double) {
        let previousWeight = dailyMetrics.weight.current
        dailyMetrics.weight.current = weight
        dailyMetrics.weight.lost = max(0, previousWeight - weight)
        persistDailyStats(weight: weight)
        Task {
            guard let userId = authService.getCurrentAuthUser()?.uid else { return }
            try? await db.collection("users").document(userId).updateData([
                "weight": weight,
                "updatedAt": Timestamp(date: Date())
            ])
        }
    }
    
    private func persistDailyStats(steps: Int? = nil, stepsGoal: Int? = nil, sleep: Double? = nil, sleepGoal: Double? = nil, weight: Double? = nil) {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        Task {
            try? await dailyStatsService.saveTodayStats(
                userId: userId,
                steps: steps,
                stepsGoal: stepsGoal,
                sleep: sleep,
                sleepGoal: sleepGoal,
                weight: weight
            )
        }
    }
    
    // MARK: - Mock Data Generators
    
    static func generateMockStreakData() -> StreakData {
        let calendar = Calendar.current
        let today = Date()
        
        let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
        var activities: [DayActivity] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i - 6, to: today) ?? today
            let dayName = dayNames[i]
            // Mark last 6 days as completed, today as incomplete
            let isCompleted = i < 6
            
            activities.append(DayActivity(
                dayName: dayName,
                date: date,
                isCompleted: isCompleted
            ))
        }
        
        return StreakData(
            weeklyActivities: activities,
            currentStreak: 6
        )
    }
    
    static func generateEmptyDailyMetrics() -> DailyMetrics {
        return DailyMetrics(
            weight: WeightMetric(current: 0, target: 0, lost: 0),
            water: WaterMetric(current: 0, goal: 0),
            sleep: SleepMetric(current: 0, goal: 0),
            steps: StepsMetric(current: 0, goal: 0)
        )
    }

    static func generateMockDailyMetrics() -> DailyMetrics {
        return DailyMetrics(
            weight: WeightMetric(
                current: 70.0,
                target: 65.0,
                lost: 10.0
            ),
            water: WaterMetric(
                current: 6,
                goal: 10
            ),
            sleep: SleepMetric(
                current: 6.5,
                goal: 7.0
            ),
            steps: StepsMetric(
                current: 6000,
                goal: 10000
            )
        )
    }
}
