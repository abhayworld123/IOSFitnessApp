import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var metrics: DashboardMetrics
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    
    init() {
        // Initialize with mock data
        self.metrics = DashboardViewModel.generateMockData()
    }
    
    // MARK: - Fetch Dashboard Data
    
    func fetchDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Replace with Firebase data fetching
        // For now, use mock data
        try? await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
        
        // In the future, fetch from Firebase:
        // - User profile (height, weight, goals)
        // - Activity data from HealthKit or manual entries
        // - Water intake logs
        // - Calorie logs
        // - Workout completion history
        
        metrics = DashboardViewModel.generateMockData()
        isLoading = false
    }
    
    // MARK: - Update Methods
    
    func updateWaterIntake(_ amount: Int) {
        metrics.waterIntake.current = max(0, metrics.waterIntake.current + amount)
        // TODO: Save to Firebase
    }
    
    func setWaterIntake(_ amount: Int) {
        metrics.waterIntake.current = max(0, min(amount, metrics.waterIntake.target * 2))
        // TODO: Save to Firebase
    }
    
    func updateCaloriesConsumed(_ amount: Int) {
        metrics.calories.consumed = max(0, metrics.calories.consumed + amount)
        // TODO: Save to Firebase
    }
    
    func updateBMI(height: Double, weight: Double) {
        metrics.bmi = BMIData(height: height, weight: weight)
        // TODO: Save to Firebase
    }
    
    // MARK: - Mock Data Generator
    
    static func generateMockData() -> DashboardMetrics {
        // Generate last 7 days of workout data
        let calendar = Calendar.current
        var weeklyData: [DailyWorkoutData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let workoutsCompleted = Int.random(in: 0...2)
            let duration = workoutsCompleted * Int.random(in: 20...45)
            let caloriesBurned = duration * Int.random(in: 5...10)
            
            weeklyData.append(DailyWorkoutData(
                date: date,
                workoutsCompleted: workoutsCompleted,
                duration: duration,
                caloriesBurned: caloriesBurned
            ))
        }
        
        // Reverse to show oldest to newest
        weeklyData.reverse()
        
        return DashboardMetrics(
            bmi: BMIData(height: 175, weight: 70), // 175cm, 70kg
            target: FitnessTarget(
                goal: .weightLoss,
                targetWeight: 65,
                targetDate: calendar.date(byAdding: .month, value: 3, to: Date()),
                currentProgress: 45.0
            ),
            activityStatus: ActivityStatus(
                steps: 8245,
                stepsGoal: 10000,
                activeMinutes: 45,
                activeMinutesGoal: 60,
                caloriesBurned: 350,
                caloriesBurnedGoal: 500
            ),
            waterIntake: WaterIntake(
                current: 1500,
                target: 2000
            ),
            calories: CalorieData(
                consumed: 1850,
                burned: 350,
                target: 2000
            ),
            workoutProgress: WorkoutProgress(weeklyData: weeklyData)
        )
    }
}

