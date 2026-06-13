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
    @Published var needsGoalSetup: Bool = false
    @Published var deviceConnectMessage: String?

    /// Apple Health connection state for step data.
    @Published var healthStatus: StepsHealthStatus = .unknown
    @Published var isHealthLoading: Bool = false

    static let defaultStepsGoal = 10_000

    private let userId: String
    private let healthKit = StepsHealthKitService.shared
    @Published private(set) var hasStepsHistory = false

    /// New user: no logged steps and Health not connected yet.
    var isEmptyTrackingState: Bool {
        healthStatus != .authorized && steps == 0 && !hasStepsHistory
    }

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
        self.stepsGoal = stepsMetric.goal > 0 ? stepsMetric.goal : Self.defaultStepsGoal
        self.lastSyncedDate = nil
        self.hourlySteps = StepsTrackingViewModel.mockHourlySteps(total: stepsMetric.current)
        if !healthKit.isHealthDataAvailable {
            healthStatus = .notAvailable
        }
    }

    func loadData() async {
        isLoading = true
        needsGoalSetup = false
        defer { isLoading = false }

        if let todayStats = try? await DailyStatsService.shared.fetchDailyStats(userId: userId, date: Date()) {
            steps = todayStats.steps
            stepsGoal = todayStats.stepsGoal > 0 ? todayStats.stepsGoal : Self.defaultStepsGoal
            hourlySteps = StepsTrackingViewModel.mockHourlySteps(total: steps)
        } else {
            steps = 0
            stepsGoal = Self.defaultStepsGoal
            hourlySteps = StepsTrackingViewModel.mockHourlySteps(total: 0)
        }

        hasStepsHistory = await checkStepsHistory()

        if healthKit.isHealthDataAvailable {
            // If already authorized from a prior session, try a silent refresh.
            if healthStatus == .authorized {
                await loadTodayStepsFromHealth()
            }
        } else {
            healthStatus = .notAvailable
        }
    }

    private func checkStepsHistory() async -> Bool {
        let cal = Calendar.current
        for dayBack in 0..<30 {
            let d = cal.date(byAdding: .day, value: -dayBack, to: Date()) ?? Date()
            if let stats = try? await DailyStatsService.shared.fetchDailyStats(userId: userId, date: d),
               stats.steps > 0 {
                return true
            }
        }
        return false
    }

    // MARK: - Apple Health

    func connectDevice() async {
        await requestHealthAuthorizationAndLoadSteps()
    }

    /// Request read access to step data and fetch today's steps if granted.
    func requestHealthAuthorizationAndLoadSteps() async {
        guard healthKit.isHealthDataAvailable else {
            healthStatus = .notAvailable
            deviceConnectMessage = "Apple Health isn't available on this device."
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
            if count > 0 { hasStepsHistory = true }
            let goal = stepsGoal > 0 ? stepsGoal : Self.defaultStepsGoal
            stepsGoal = goal
            try? await DailyStatsService.shared.saveTodayStats(userId: userId, steps: count, stepsGoal: goal)
            if count == 0 {
                deviceConnectMessage = "Apple Health is connected. No steps recorded yet today — log manually or check back later."
            } else {
                HapticFeedback.success()
            }
        } catch let error as StepsHealthKitError {
            switch error {
            case .healthKitNotAvailable:
                healthStatus = .notAvailable
                deviceConnectMessage = error.localizedDescription
            case .authorizationDenied:
                healthStatus = .denied
                deviceConnectMessage = "Health access was denied. Enable it in Settings or log steps manually."
            case .noData, .queryFailed:
                healthStatus = .error(error.localizedDescription)
                deviceConnectMessage = error.localizedDescription
            }
        } catch {
            healthStatus = .error(error.localizedDescription)
            deviceConnectMessage = error.localizedDescription
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
            if count > 0 { hasStepsHistory = true }
            try? await DailyStatsService.shared.saveTodayStats(userId: userId, steps: count, stepsGoal: stepsGoal)
        } catch {
            healthStatus = .error(error.localizedDescription)
        }
    }

    func logManualSteps(_ count: Int) async {
        let logged = max(0, count)
        steps = logged
        if stepsGoal <= 0 { stepsGoal = Self.defaultStepsGoal }
        hourlySteps = StepsTrackingViewModel.mockHourlySteps(total: logged)
        if logged > 0 { hasStepsHistory = true }
        do {
            try await DailyStatsService.shared.saveTodayStats(
                userId: userId,
                steps: logged,
                stepsGoal: stepsGoal
            )
            HapticFeedback.success()
        } catch {
            deviceConnectMessage = "Couldn't save steps: \(error.localizedDescription)"
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
        HapticFeedback.impact(style: .light)
    }

    /// Mock hourly distribution for "Today" chart (4 buckets: 12 AM, 6, 12 PM, 6 PM)
    private static func mockHourlySteps(total: Int) -> [Int] {
        let ratios: [Double] = [0.1, 0.2, 0.45, 0.25]
        return ratios.map { Int(Double(total) * $0) }
    }
}
