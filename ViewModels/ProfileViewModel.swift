import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var totalWorkoutsCompleted: Int = 0
    @Published var totalTimeExercised: Int = 0 // in minutes
    @Published var currentStreak: Int = 0
    @Published var recentWorkouts: [WorkoutHistoryItem] = []
    @Published var monthlyChartData: [DailyWorkoutData] = []
    @Published var monthlyStepsData: [DailyWorkoutData] = []
    @Published var monthlyWaterData: [DailyWorkoutData] = []
    @Published var badges: [Badge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let authService = AuthService.shared
    private let workoutService = WorkoutService.shared
    private let dailyStatsService = DailyStatsService.shared
    private let waterService = WaterTrackingService.shared
    
    // MARK: - Fetch Statistics
    
    static let mockBadges: [Badge] = [
        Badge(id: "1", title: "1st Activity", imageName: "badge"),
        Badge(id: "2", title: "5th Activity", imageName: "badge"),
        Badge(id: "3", title: "On a roll", imageName: "fire"),
        Badge(id: "4", title: "Reached weight goals", imageName: "kg")
    ]
    
    func fetchUserStatistics() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else {
            badges = ProfileViewModel.mockBadges
            return
        }
        
        isLoading = true
        errorMessage = nil
        badges = ProfileViewModel.mockBadges
        
        do {
            // Fetch completed workouts
            let completedWorkoutsSnapshot = try await db.collection("userProgress")
                .document(userId)
                .collection("completedWorkouts")
                .getDocuments()
            
            var completedWorkoutIds: [String] = []
            var workoutDateMap: [String: Date] = [:]
            var totalMinutes = 0
            
            for document in completedWorkoutsSnapshot.documents {
                let data = document.data()
                if let completed = data["completed"] as? Bool, completed {
                    let workoutId = document.documentID
                    completedWorkoutIds.append(workoutId)
                    
                    if let completedDate = (data["completedDate"] as? Timestamp)?.dateValue() {
                        workoutDateMap[workoutId] = completedDate
                    } else if let lastUpdated = (data["lastUpdated"] as? Timestamp)?.dateValue() {
                        // Fallback to lastUpdated if completedDate is not available
                        workoutDateMap[workoutId] = lastUpdated
                    }
                    
                    // Fetch workout to get duration
                    if let workout = try? await workoutService.fetchWorkout(id: workoutId) {
                        totalMinutes += workout.duration
                    }
                }
            }
            
            totalWorkoutsCompleted = completedWorkoutIds.count
            totalTimeExercised = totalMinutes
            let completionDates = Array(workoutDateMap.values)
            currentStreak = calculateStreak(from: completionDates)
            
            // Build monthly chart data for current month
            monthlyChartData = buildMonthlyChartData(from: completionDates)
            
            // Fetch monthly steps and water for analytics
            await fetchMonthlyStepsAndWater(userId: userId)
            
            // Fetch recent workouts for history
            await fetchRecentWorkouts(workoutIds: completedWorkoutIds, workoutDateMap: workoutDateMap)
            
        } catch {
            errorMessage = "Failed to load statistics. Please try again."
            print("Error fetching statistics: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Monthly Steps & Water
    
    private func fetchMonthlyStepsAndWater(userId: String) async {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return }
        let rangeEnd = calendar.date(byAdding: .day, value: 1, to: monthEnd)!
        
        do {
            let dailyStats = try await dailyStatsService.fetchMonthlyDailyStats(userId: userId, startDate: monthStart, endDate: monthEnd)
            let waterRecords = try await waterService.fetchWeeklyData(userId: userId, startDate: monthStart, endDate: rangeEnd)
            
            var stepsByDay: [Date: Int] = [:]
            var waterByDay: [Date: Int] = [:]
            for s in dailyStats {
                stepsByDay[calendar.startOfDay(for: s.date)] = s.steps
            }
            for w in waterRecords {
                waterByDay[calendar.startOfDay(for: w.date)] = w.glassesConsumed
            }
            
            guard let dayCount = calendar.range(of: .day, in: .month, for: now)?.count else { return }
            var stepsChart: [DailyWorkoutData] = []
            var waterChart: [DailyWorkoutData] = []
            for offset in 0..<dayCount {
                guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else { continue }
                let dayStart = calendar.startOfDay(for: date)
                stepsChart.append(DailyWorkoutData(date: date, workoutsCompleted: stepsByDay[dayStart] ?? 0, duration: 0, caloriesBurned: 0))
                waterChart.append(DailyWorkoutData(date: date, workoutsCompleted: waterByDay[dayStart] ?? 0, duration: 0, caloriesBurned: 0))
            }
            monthlyStepsData = stepsChart
            monthlyWaterData = waterChart
        } catch {
            print("ProfileViewModel: fetch monthly steps/water failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Monthly Chart Data
    
    private func buildMonthlyChartData(from completionDates: [Date]) -> [DailyWorkoutData] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart),
              let dayCount = calendar.range(of: .day, in: .month, for: now)?.count else {
            return []
        }
        var dayCounts: [Date: Int] = [:]
        for offset in 0..<dayCount {
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else { continue }
            dayCounts[date] = 0
        }
        for d in completionDates {
            let dayStart = calendar.startOfDay(for: d)
            if dayStart >= monthStart && dayStart <= monthEnd {
                dayCounts[dayStart, default: 0] += 1
            }
        }
        return dayCounts.sorted(by: { $0.key < $1.key }).map { date, count in
            DailyWorkoutData(date: date, workoutsCompleted: count, duration: 0, caloriesBurned: 0)
        }
    }
    
    // MARK: - Fetch Recent Workouts
    
    private func fetchRecentWorkouts(workoutIds: [String], workoutDateMap: [String: Date]) async {
        var historyItems: [WorkoutHistoryItem] = []
        
        // Fetch workout details for recent ones (last 20)
        let recentIds = Array(workoutIds.prefix(20))
        
        for workoutId in recentIds {
            do {
                if let workout = try await workoutService.fetchWorkout(id: workoutId),
                   let completionDate = workoutDateMap[workoutId] {
                    historyItems.append(WorkoutHistoryItem(
                        workout: workout,
                        completedDate: completionDate
                    ))
                }
            } catch {
                print("Failed to fetch workout \(workoutId): \(error.localizedDescription)")
            }
        }
        
        // Sort by completion date (most recent first)
        historyItems.sort { $0.completedDate > $1.completedDate }
        recentWorkouts = historyItems
    }
    
    // MARK: - Calculate Streak
    
    private func calculateStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = dates.sorted(by: >) // Most recent first
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            let dayStart = calendar.startOfDay(for: date)
            
            if calendar.isDate(dayStart, inSameDayAs: currentDate) {
                // Same day, continue
                continue
            } else if calendar.date(byAdding: .day, value: -1, to: currentDate) == dayStart {
                // Consecutive day
                streak += 1
                currentDate = dayStart
            } else {
                // Streak broken
                break
            }
        }
        
        // Check if today's workout is completed
        let todayStart = calendar.startOfDay(for: Date())
        if let mostRecent = sortedDates.first,
           calendar.isDate(calendar.startOfDay(for: mostRecent), inSameDayAs: todayStart) {
            streak += 1
        }
        
        return streak
    }
    
    // MARK: - Update Profile
    
    func updateProfile(name: String, email: String) async throws {
        guard let userId = authService.getCurrentAuthUser()?.uid else {
            throw ProfileError.notAuthenticated
        }
        
        try await db.collection("users").document(userId).updateData([
            "name": name,
            "email": email,
            "updatedAt": Timestamp(date: Date())
        ])
        
        // Refresh user data
        if let user = try? await authService.fetchCurrentUserData() {
            // User data will be updated via AuthService's published property
        }
    }
}

// MARK: - Workout History Item

struct WorkoutHistoryItem: Identifiable {
    let id: String
    let workout: Workout
    let completedDate: Date
    
    init(workout: Workout, completedDate: Date) {
        self.id = workout.id
        self.workout = workout
        self.completedDate = completedDate
    }
}

// MARK: - Profile Errors

enum ProfileError: LocalizedError {
    case notAuthenticated
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to update your profile"
        case .updateFailed:
            return "Failed to update profile. Please try again."
        }
    }
}

