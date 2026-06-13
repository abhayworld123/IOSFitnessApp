import Foundation
import HealthKit

enum SleepHealthKitError: LocalizedError {
    case healthKitNotAvailable
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "Health data is not available on this device."
        case .queryFailed(let error):
            return error.localizedDescription
        }
    }
}

/// Reads sleep duration from Apple Health (sleep analysis samples).
final class SleepHealthKitService {
    static let shared = SleepHealthKitService()

    private let healthStore = HKHealthStore()

    private init() {}

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var sleepType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable, let sleepType else {
            throw SleepHealthKitError.healthKitNotAvailable
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: [sleepType]) { _, error in
                if let error {
                    continuation.resume(throwing: SleepHealthKitError.queryFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Sum asleep intervals between `start` and `end` (hours).
    func fetchSleepHours(from start: Date, to end: Date) async throws -> Double {
        guard isHealthDataAvailable, let sleepType else {
            throw SleepHealthKitError.healthKitNotAvailable
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: SleepHealthKitError.queryFailed(error))
                    return
                }

                var total: TimeInterval = 0
                for case let sample as HKCategorySample in samples ?? [] where asleepValues.contains(sample.value) {
                    total += sample.endDate.timeIntervalSince(sample.startDate)
                }
                continuation.resume(returning: total / 3600.0)
            }
            healthStore.execute(query)
        }
    }

    /// Sleep from yesterday evening through now (typical “last night”).
    func fetchRecentSleepHours() async throws -> Double {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .hour, value: -12, to: startOfToday) ?? startOfToday
        return try await fetchSleepHours(from: start, to: Date())
    }
}
