import Foundation
import Combine

@MainActor
final class SleepTrackerViewModel: ObservableObject {
    let userId: String
    @Published var asleepHours: Double = 0
    @Published var goalHours: Double = 8
    @Published var deepSleepPercent: Double = 0.24
    @Published private(set) var avgSleepHours7d: Double = 0
    @Published var hitSleepWindow: Bool?
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var deviceConnectMessage: String?

    static let defaultGoalHours: Double = 8

    private let dailyStatsService = DailyStatsService.shared
    private let healthKit = SleepHealthKitService.shared
    private var hitWindowKey: String { "sleepHitWindow_\(userId)" }
    private var deepKey: String { "sleepDeepPercent_\(userId)" }
    private var syncKey: String { "healthLastSync_\(userId)" }

    init(userId: String) {
        self.userId = userId
        if let t = UserDefaults.standard.object(forKey: syncKey) as? TimeInterval {
            lastSyncDate = Date(timeIntervalSince1970: t)
        }
    }

    /// New user or no logged sleep in the last 30 days.
    var isEmptyTrackingState: Bool {
        asleepHours <= 0 && !hasSleepHistory
    }

    private(set) var hasSleepHistory = false

    func load() async {
        isLoading = true
        defer { isLoading = false }

        asleepHours = 0
        goalHours = Self.defaultGoalHours

        if let stats = try? await dailyStatsService.fetchDailyStats(userId: userId, date: Date()) {
            asleepHours = max(0, stats.sleep)
            if stats.sleepGoal > 0 {
                goalHours = stats.sleepGoal
            }
        }

        hasSleepHistory = await checkSleepHistory()
        await load7DayAverage()

        if UserDefaults.standard.object(forKey: hitWindowKey) != nil {
            hitSleepWindow = UserDefaults.standard.bool(forKey: hitWindowKey)
        } else {
            hitSleepWindow = nil
        }

        let d = UserDefaults.standard.double(forKey: deepKey)
        if d > 0 { deepSleepPercent = min(0.5, max(0.05, d)) }
    }

    private func checkSleepHistory() async -> Bool {
        let cal = Calendar.current
        for dayBack in 0..<30 {
            let d = cal.date(byAdding: .day, value: -dayBack, to: Date()) ?? Date()
            if let stats = try? await dailyStatsService.fetchDailyStats(userId: userId, date: d),
               stats.sleep > 0 {
                return true
            }
        }
        return false
    }

    private func load7DayAverage() async {
        let cal = Calendar.current
        var sum: Double = 0
        var n = 0
        for dayBack in 0..<7 {
            let d = cal.date(byAdding: .day, value: -dayBack, to: Date()) ?? Date()
            if let stats = try? await dailyStatsService.fetchDailyStats(userId: userId, date: d), stats.sleep > 0 {
                sum += stats.sleep
                n += 1
            }
        }
        if n == 0 {
            avgSleepHours7d = 0
        } else {
            avgSleepHours7d = sum / Double(n)
        }
    }

    var progressTowardGoal: Double {
        guard goalHours > 0 else { return 0 }
        return min(1, asleepHours / goalHours)
    }

    var deepPortionOfFill: Double { deepSleepPercent }

    var percentVsAverageLabel: String {
        guard avgSleepHours7d > 0, asleepHours > 0 else { return "— VS AVG" }
        let ratio = (asleepHours - avgSleepHours7d) / avgSleepHours7d
        let pct = Int((ratio * 100).rounded())
        if pct == 0 { return "0% VS AVG" }
        if pct > 0 { return "+\(pct)% VS AVG" }
        return "\(pct)% VS AVG"
    }

    var percentVsAverageIsPositive: Bool {
        guard avgSleepHours7d > 0 else { return true }
        return asleepHours >= avgSleepHours7d
    }

    func setHitWindow(_ value: Bool) {
        hitSleepWindow = value
        UserDefaults.standard.set(value, forKey: hitWindowKey)
        HapticFeedback.impact(style: .light)
    }

    func markSyncNow() {
        let now = Date()
        lastSyncDate = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: syncKey)
        HapticFeedback.impact(style: .medium)
    }

    func logManualSleep(hours: Double) async {
        let clamped = max(0.25, min(16, hours))
        do {
            try await dailyStatsService.saveTodayStats(
                userId: userId,
                sleep: clamped,
                sleepGoal: goalHours
            )
            asleepHours = clamped
            hasSleepHistory = true
            await load7DayAverage()
            HapticFeedback.success()
        } catch {
            deviceConnectMessage = "Couldn’t save sleep: \(error.localizedDescription)"
        }
    }

    func connectDevice() async {
        deviceConnectMessage = nil

        guard healthKit.isHealthDataAvailable else {
            deviceConnectMessage = "Apple Health isn’t available on this device. Log sleep manually instead."
            return
        }

        do {
            try await healthKit.requestAuthorization()
            markSyncNow()
            let hours = try await healthKit.fetchRecentSleepHours()
            if hours > 0.1 {
                try await dailyStatsService.saveTodayStats(
                    userId: userId,
                    sleep: hours,
                    sleepGoal: goalHours
                )
                asleepHours = hours
                hasSleepHistory = true
                await load7DayAverage()
                HapticFeedback.success()
            } else {
                deviceConnectMessage = "Apple Health is connected. No sleep data found yet — log manually or sync after tonight."
            }
        } catch {
            deviceConnectMessage = error.localizedDescription
        }
    }
}
