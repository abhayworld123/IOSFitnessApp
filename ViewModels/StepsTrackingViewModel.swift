import Foundation
import SwiftUI

/// Reflects Apple Health connection and permission state for step data.
enum StepsHealthStatus: Equatable {
    case unknown
    case notAvailable
    case notDetermined
    case authorized
    case denied
    case error(String)

    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}

@MainActor
class StepsTrackingViewModel: ObservableObject {
    @Published var steps: Int
    @Published var stepsGoal: Int
    @Published var lastSyncedDate: Date?
    @Published var hourlySteps: [Int]
    @Published var reminderEnabled: Bool = false
    @Published var isLoading: Bool = false
    /// True when user has no steps goal set — show goal setup popup.
    @Published var needsGoalSetup: Bool = false

    /// Apple Health connection state for step data.
    @Published var healthStatus: StepsHealthStatus = .unknown
    /// True while requesting Health authorization or fetching steps from Health.
    @Published var isHealthLoading: Bool = false

    private let userId: String
    private let healthKit = StepsHealthKitService.shared

    /// Distance in km (derived from steps: ~0.00043 km per step to match 6000 → 2.6 km)
    var distanceKm: Double {
        Double(steps) * 0.000433
    }

    var formattedDistance: String {
        String(format: "%.1f km", distanceKm)
    }

    var lastSyncedText: String {
        guard let date = lastSyncedDate else { return "Not synced" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, h:mm a"
        return "Last synced: \(formatter.string(from: date))"
    }

    init(userId: String, stepsMetric: StepsMetric) {
        self.userId = userId
        self.steps = stepsMetric.current
        self.stepsGoal = stepsMetric.goal
        self.lastSyncedDate = Date()
        self.hourlySteps = StepsTrackingViewModel.mockHourlySteps(total: stepsMetric.current)
        if !healthKit.isHealthDataAvailable {
            healthStatus = .notAvailable
        }
    }

    func loadData() async {
        isLoading = true
        needsGoalSetup = false
        if let todayStats = try? await DailyStatsService.shared.fetchDailyStats(userId: userId, date: Date()) {
            steps = todayStats.steps
            stepsGoal = todayStats.stepsGoal
            hourlySteps = StepsTrackingViewModel.mockHourlySteps(total: steps)
            if stepsGoal <= 0 {
                needsGoalSetup = true
            }
        } else {
            needsGoalSetup = true
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
        isLoading = false
    }

    // MARK: - Apple Health

    /// Request read access to step data and fetch today's steps if granted.
    func requestHealthAuthorizationAndLoadSteps() async {
        guard healthKit.isHealthDataAvailable else {
            healthStatus = .notAvailable
            return
        }
        isHealthLoading = true
        healthStatus = .notDetermined
        defer { isHealthLoading = false }

        do {
            try await healthKit.requestAuthorization()
            let count = try await healthKit.fetchTodaySteps()
            healthStatus = .authorized
            steps = count
            hourlySteps = StepsTrackingViewModel.mockHourlySteps(total: count)
            lastSyncedDate = Date()
            try? await DailyStatsService.shared.saveTodayStats(userId: userId, steps: count, stepsGoal: stepsGoal)
            if stepsGoal <= 0 {
                needsGoalSetup = true
            }
        } catch let error as StepsHealthKitError {
            switch error {
            case .healthKitNotAvailable:
                healthStatus = .notAvailable
            case .authorizationDenied:
                healthStatus = .denied
            case .noData, .queryFailed:
                healthStatus = .error(error.localizedDescription)
            }
        } catch {
            healthStatus = .error(error.localizedDescription)
        }
    }

    /// Fetch today's steps from Apple Health (call when already authorized).
    func loadTodayStepsFromHealth() async {
        guard healthStatus == .authorized else { return }
        isHealthLoading = true
        defer { isHealthLoading = false }
        do {
            let count = try await healthKit.fetchTodaySteps()
            steps = count
            hourlySteps = StepsTrackingViewModel.mockHourlySteps(total: count)
            lastSyncedDate = Date()
            try? await DailyStatsService.shared.saveTodayStats(userId: userId, steps: count, stepsGoal: stepsGoal)
        } catch {
            healthStatus = .error(error.localizedDescription)
        }
    }

    func updateStepsGoal(_ newGoal: Int) {
        guard newGoal > 0 else { return }
        stepsGoal = newGoal
        Task {
            try? await DailyStatsService.shared.saveTodayStats(
                userId: userId,
                steps: steps,
                stepsGoal: stepsGoal
            )
        }
    }

    func toggleReminder() {
        reminderEnabled.toggle()
    }

    /// Mock hourly distribution for "Today" chart (4 buckets: 12 AM, 6, 12 PM, 6 PM)
    private static func mockHourlySteps(total: Int) -> [Int] {
        let ratios: [Double] = [0.1, 0.2, 0.45, 0.25]
        return ratios.map { Int(Double(total) * $0) }
    }
}
