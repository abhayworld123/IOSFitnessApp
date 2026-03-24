import Foundation
import HealthKit

/// Errors that can occur when interacting with HealthKit for step data.
enum StepsHealthKitError: LocalizedError {
    case healthKitNotAvailable
    case authorizationDenied
    case noData
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "Health data is not available on this device."
        case .authorizationDenied:
            return "Access to step data was denied."
        case .noData:
            return "No step data found for today."
        case .queryFailed(let error):
            return error.localizedDescription
        }
    }
}

/// Service that reads step count from Apple Health (HealthKit).
/// Supports requesting authorization and fetching today's cumulative step count.
final class StepsHealthKitService {
    static let shared = StepsHealthKitService()

    private let healthStore = HKHealthStore()

    private init() {}

    /// Returns whether HealthKit is available on this device (e.g. not on Simulator without Health).
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Step count type to request read access for.
    private var stepCountType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .stepCount)
    }

    /// Types to read (step count only for now).
    private var typesToRead: Set<HKObjectType> {
        guard let step = stepCountType else { return [] }
        return [step]
    }

    /// Request authorization to read step count. The system will show the Health permission sheet.
    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw StepsHealthKitError.healthKitNotAvailable
        }
        guard let stepType = stepCountType else {
            throw StepsHealthKitError.healthKitNotAvailable
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: typesToRead) { _, error in
                if let error = error {
                    continuation.resume(throwing: StepsHealthKitError.queryFailed(error))
                    return
                }
                continuation.resume()
            }
        }
    }

    /// Check current authorization status for step count (read).
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }

    /// Fetch today's total step count (from start of local day to now).
    /// HealthKit aggregates from all sources (e.g. iPhone, Apple Watch).
    func fetchTodaySteps() async throws -> Int {
        guard isHealthDataAvailable else {
            throw StepsHealthKitError.healthKitNotAvailable
        }
        guard let stepType = stepCountType else {
            throw StepsHealthKitError.healthKitNotAvailable
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: StepsHealthKitError.queryFailed(error))
                    return
                }
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }
}
