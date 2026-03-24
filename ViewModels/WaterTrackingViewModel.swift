import Foundation
import SwiftUI

@MainActor
class WaterTrackingViewModel: ObservableObject {
    @Published var currentIntake: WaterIntakeRecord?
    @Published var weeklyData: [WaterIntakeRecord] = []
    @Published var goal: Int = 0
    @Published var glassSize: Int = 250
    @Published var reminder: WaterReminder?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var showGoalReachedToast: Bool = false
    /// True when user has no water record yet — show goal setup popup.
    @Published var needsGoalSetup: Bool = false
    
    private let waterService = WaterTrackingService.shared
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    // MARK: - Load Data
    
    func loadData() async {
        guard !userId.isEmpty else {
            errorMessage = "Please sign in to track water."
            return
        }
        isLoading = true
        errorMessage = nil
        needsGoalSetup = false
        
        do {
            // Load today's intake — don't create a default record for new users
            let todayIntake = try await waterService.fetchTodayIntake(userId: userId, date: selectedDate)
            if let intake = todayIntake {
                currentIntake = intake
                goal = intake.goal
                glassSize = intake.glassSize
            } else {
                currentIntake = nil
                goal = 0
                needsGoalSetup = true
            }
            
            // Load weekly data
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            
            weeklyData = try await waterService.fetchWeeklyData(
                userId: userId,
                startDate: startOfWeek,
                endDate: endOfWeek
            )
            
            // Load reminder
            reminder = try await waterService.fetchReminder(userId: userId)
        } catch {
            errorMessage = "Failed to load water intake data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Counter Methods

    func incrementGlass() {
        if currentIntake == nil {
            guard goal > 0 else { return }
            currentIntake = WaterIntakeRecord(
                userId: userId,
                date: selectedDate,
                goal: goal,
                glassSize: glassSize
            )
        }
        guard var intake = currentIntake else { return }
        intake.glassesConsumed += 1
        intake.updatedAt = Date()
        let reachedGoal = intake.glassesConsumed >= intake.goal
        currentIntake = intake
        if reachedGoal {
            showGoalReachedToast = true
        }
        HapticFeedback.impact()
        Task {
            await saveIntake()
        }
    }

    func clearGoalReachedToast() {
        showGoalReachedToast = false
    }
    
    func decrementGlass() {
        if currentIntake == nil { return }
        guard var intake = currentIntake else { return }
        if intake.glassesConsumed > 0 {
            intake.glassesConsumed -= 1
            intake.updatedAt = Date()
            currentIntake = intake
            HapticFeedback.impact()
            Task {
                await saveIntake()
            }
        }
    }
    
    // MARK: - Update Goal
    
    func updateGoal(_ newGoal: Int) {
        let savedGoal = max(1, newGoal)
        goal = savedGoal
        if currentIntake == nil {
            // First-time goal set: create today's record and save to Firebase
            currentIntake = WaterIntakeRecord(
                userId: userId,
                date: selectedDate,
                glassesConsumed: 0,
                goal: goal,
                glassSize: glassSize
            )
            needsGoalSetup = false
            Task {
                await saveIntake()
            }
        } else {
            guard var intake = currentIntake else { return }
            intake.goal = goal
            intake.updatedAt = Date()
            currentIntake = intake
            Task {
                await saveIntake()
            }
        }
    }
    
    // MARK: - Update Glass Size
    
    func updateGlassSize(_ newSize: Int) {
        glassSize = max(100, newSize)
        guard var intake = currentIntake else { return }
        intake.glassSize = glassSize
        intake.updatedAt = Date()
        currentIntake = intake
        Task {
            await saveIntake()
        }
    }
    
    // MARK: - Save Intake
    
    private func saveIntake() async {
        guard let intake = currentIntake else { return }
        
        do {
            try await waterService.saveIntake(intake)
            // Don't reload here — it can overwrite local state before Firestore propagates
        } catch {
            errorMessage = "Failed to save water intake: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reminder Methods

    /// Save reminder on/off and times; schedules or removes local notifications.
    func saveReminderSettings(isEnabled: Bool, times: [Date]) async {
        let reminderTimes = times.map { normalizeTimeOfDay($0) }
        let updated: WaterReminder
        if let existing = reminder {
            updated = WaterReminder(
                id: existing.id,
                userId: userId,
                isEnabled: isEnabled,
                reminderTimes: reminderTimes,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else {
            updated = WaterReminder(
                userId: userId,
                isEnabled: isEnabled,
                reminderTimes: reminderTimes,
                createdAt: Date(),
                updatedAt: Date()
            )
        }

        do {
            try await waterService.saveReminder(updated)
            reminder = updated

            if isEnabled, !reminderTimes.isEmpty {
                let granted = await WaterReminderNotificationService.requestAuthorization()
                if granted {
                    await WaterReminderNotificationService.scheduleReminders(at: reminderTimes)
                }
            } else {
                await WaterReminderNotificationService.removeAllWaterReminders()
            }
        } catch {
            errorMessage = "Failed to save reminder: \(error.localizedDescription)"
        }
    }

    /// Normalize to today's date with same hour/minute for consistent storage.
    private func normalizeTimeOfDay(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: date)
        return cal.date(bySettingHour: comps.hour ?? 9, minute: comps.minute ?? 0, second: 0, of: Date()) ?? date
    }
    
    // MARK: - Progress Message
    
    var progressMessage: (title: String, subtitle: String) {
        guard goal > 0 else {
            return ("Set your goal", "Tap the pencil to choose your daily glasses")
        }
        guard let intake = currentIntake else {
            return ("Get started!", "Drink your first glass of water")
        }
        
        let progress = intake.progress
        
        if progress >= 1.0 {
            return ("Goal achieved! 🎉", "Great job staying hydrated!")
        } else if progress >= 0.75 {
            return ("Almost there!", "Have another glass to reach your goal")
        } else if progress >= 0.5 {
            return ("Half way there!", "Have another glass in next 60 minutes")
        } else if progress >= 0.25 {
            return ("Keep going!", "You're making good progress")
        } else {
            return ("Get started!", "Drink your first glass of water")
        }
    }
    
    // MARK: - Weekly Data Helper
    
    func getIntakeForDay(_ dayIndex: Int) -> Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: startOfWeek)!
        
        if let intake = weeklyData.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            return intake.glassesConsumed
        }
        return 0
    }
}
