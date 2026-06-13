import Foundation
import SwiftUI

/// Day / Week / month layout for the schedule screen (Figma: Trakkit calendar).
enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
}

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentPlan: WorkoutPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var displayMode: CalendarDisplayMode = .week
    @Published var userWorkoutById: [String: Workout] = [:]
    @Published var personalBestStreakWeeks: Int
    
    private let planService = WorkoutPlanService.shared
    private let workoutService = WorkoutService.shared
    
    var userId: String?
    
    private let personalBestKey = "calendarPersonalBestStreakWeeks"
    
    init(userId: String? = nil) {
        self.userId = userId
        let key = "calendarPersonalBestStreakWeeks"
        let stored = UserDefaults.standard.integer(forKey: key)
        self.personalBestStreakWeeks = stored > 0 ? stored : 8
    }
    
    // MARK: - Streak (weeks UI)
    
    var currentStreakWeeks: Int {
        let days = calculateCurrentStreak()
        return max(0, (days + 6) / 7)
    }
    
    func refreshPersonalBestIfNeeded() {
        let w = currentStreakWeeks
        if w > personalBestStreakWeeks {
            personalBestStreakWeeks = w
            UserDefaults.standard.set(w, forKey: personalBestKey)
        }
    }
    
    // MARK: - User workouts (titles, duration, category)
    
    func loadUserWorkoutCache() async {
        guard let userId, !userId.isEmpty else { return }
        do {
            let list = try await workoutService.fetchUserWorkouts(userId: userId)
            await MainActor.run {
                userWorkoutById = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
            }
        } catch {
            // Non-fatal: fall back to generic labels
        }
    }
    
    func displayTitle(for day: WorkoutDay?) -> String {
        guard let day else { return "No schedule available" }
        if day.isRestDay { return "Rest Day" }
        guard let id = day.workoutId else { return "No schedule available" }
        return userWorkoutById[id]?.title ?? "Workout"
    }
    
    func displayDurationMinutes(for day: WorkoutDay?) -> Int {
        guard let day, let id = day.workoutId, !day.isRestDay, let w = userWorkoutById[id] else { return 55 }
        return max(1, w.duration)
    }
    
    func displayCategoryLabel(for day: WorkoutDay?) -> String {
        guard let day else { return "Strength" }
        if day.isRestDay { return "Recovery" }
        guard let id = day.workoutId, let w = userWorkoutById[id] else { return "Strength" }
        return w.category.displayName
    }
    
    // MARK: - Mon–Fri strip (this week, completion for calendar strip)
    
    /// Monday … Friday in the same week as `date`.
    func mondayThroughFridayDates(containing date: Date) -> [Date] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .weekOfYear, for: date) else { return [] }
        var monday = interval.start
        while cal.component(.weekday, from: monday) != 2 { // 2 = Monday
            monday = cal.date(byAdding: .day, value: 1, to: monday) ?? monday
        }
        return (0..<5).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }
    
    func isStripDayCompleted(_ date: Date) -> Bool {
        isDateCompleted(date)
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
    
    /// Plan `dayOfWeek` uses the same mapping as the rest of the app: `(weekday + 5) % 7` with `weekday` = `Calendar` component (1…7).
    func getWorkoutForDate(_ date: Date) -> WorkoutDay? {
        guard let plan = currentPlan else { return nil }
        let calendar = Calendar.current
        let dayOfWeek = (calendar.component(.weekday, from: date) + 5) % 7
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
        let now = Date()
        currentMonth = now
        selectedDate = now
    }
    
    // MARK: - Navigation (Figma chevrons)
    
    func stepPeriodForward() {
        let cal = Calendar.current
        switch displayMode {
        case .day:
            selectedDate = cal.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = cal.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
        case .month:
            if let n = cal.date(byAdding: .month, value: 1, to: currentMonth) {
                currentMonth = n
                alignSelectedToSameDayInMonthIfPossible()
            }
        }
        syncMonthWithSelectedIfNeeded()
    }
    
    func stepPeriodBack() {
        let cal = Calendar.current
        switch displayMode {
        case .day:
            selectedDate = cal.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = cal.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        case .month:
            if let n = cal.date(byAdding: .month, value: -1, to: currentMonth) {
                currentMonth = n
                alignSelectedToSameDayInMonthIfPossible()
            }
        }
        syncMonthWithSelectedIfNeeded()
    }
    
    private func alignSelectedToSameDayInMonthIfPossible() {
        let cal = Calendar.current
        let day = min(cal.component(.day, from: selectedDate), cal.range(of: .day, in: .month, for: currentMonth)?.count ?? 28)
        var c = cal.dateComponents([.year, .month], from: currentMonth)
        c.day = day
        c.hour = 12
        if let d = cal.date(from: c) { selectedDate = d }
    }
    
    private func syncMonthWithSelectedIfNeeded() {
        let cal = Calendar.current
        if let m = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) {
            currentMonth = m
        }
    }
    
    /// Keep month grid aligned when changing Day/Week/Month chips.
    func syncMonthWithSelectedForPicker() {
        syncMonthWithSelectedIfNeeded()
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
