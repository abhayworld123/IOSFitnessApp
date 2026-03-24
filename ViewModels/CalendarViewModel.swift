import Foundation
import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentPlan: WorkoutPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    
    private let planService = WorkoutPlanService.shared
    
    var userId: String?
    
    init(userId: String? = nil) {
        self.userId = userId
    }
    
    // MARK: - Fetch Plan
    
    func fetchUserPlan() async {
        guard let userId = userId else {
            errorMessage = "User ID not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            currentPlan = try await planService.fetchUserPlan(userId: userId)
        } catch {
            errorMessage = "Failed to load workout plan: \(error.localizedDescription)"
            print("Error fetching plan: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Calendar Helpers
    
    func getWorkoutForDate(_ date: Date) -> WorkoutDay? {
        guard let plan = currentPlan else { return nil }
        let calendar = Calendar.current
        let dayOfWeek = (calendar.component(.weekday, from: date) + 5) % 7 // Convert to 0-based (Sunday = 0)
        return plan.workouts.first { $0.dayOfWeek == dayOfWeek }
    }
    
    func isDateCompleted(_ date: Date) -> Bool {
        guard let day = getWorkoutForDate(date) else { return false }
        return day.completed
    }
    
    func isDateRestDay(_ date: Date) -> Bool {
        guard let day = getWorkoutForDate(date) else { return false }
        return day.isRestDay
    }
    
    func hasWorkoutOnDate(_ date: Date) -> Bool {
        guard let day = getWorkoutForDate(date) else { return false }
        return !day.isRestDay && day.workoutId != nil
    }
    
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // MARK: - Month Navigation
    
    func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func goToToday() {
        currentMonth = Date()
        selectedDate = Date()
    }
    
    // MARK: - Week View Helpers
    
    func getWeekDates(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        
        var weekDates: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                weekDates.append(day)
            }
        }
        return weekDates
    }
    
    // MARK: - Streak Calculation
    
    func calculateCurrentStreak() -> Int {
        guard let plan = currentPlan else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        // Check backwards from today
        for _ in 0..<30 { // Check up to 30 days back
            let dayOfWeek = (calendar.component(.weekday, from: checkDate) + 5) % 7
            if let day = plan.workouts.first(where: { $0.dayOfWeek == dayOfWeek }) {
                if day.completed {
                    streak += 1
                } else if !day.isRestDay {
                    // If it's a workout day but not completed, break the streak
                    break
                }
            }
            
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDate
        }
        
        return streak
    }
}
