import Foundation
import FirebaseFirestore

@MainActor
final class WeightTrackingViewModel: ObservableObject {
    let userId: String

    @Published var displayUnit: WeightUnit = .kg
    @Published var rulerValue: Double = 70
    @Published var goalWeightKg: Double?
    @Published var history: [(date: Date, weightKg: Double)] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private let dailyStatsService = DailyStatsService.shared
    private var saveTask: Task<Void, Never>?

    init(userId: String) {
        self.userId = userId
    }

    var weightKg: Double {
        displayUnit.convert(rulerValue, to: .kg)
    }

    /// ±2.5 kg band around goal for the “ideal weight” fill (kg).
    var idealBandKg: (low: Double, high: Double)? {
        guard let g = goalWeightKg else { return nil }
        return (g - 2.5, g + 2.5)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            let data = doc.data() ?? [:]

            if let g = data["targetWeight"] as? Double {
                goalWeightKg = g
            } else {
                goalWeightKg = nil
            }

            if let wKg = data["weight"] as? Double, wKg > 0 {
                rulerValue = WeightUnit.kg.convert(wKg, to: displayUnit)
            } else {
                rulerValue = displayUnit.defaultValue
            }

            try await refreshHistory()
        } catch {
            print("WeightTracking load error: \(error.localizedDescription)")
            rulerValue = displayUnit.defaultValue
        }
    }

    func refreshHistory() async throws {
        let entries = try await dailyStatsService.fetchWeightHistory(userId: userId, daysBack: 120)
        history = entries.sorted { $0.date < $1.date }
    }

    func schedulePersistWeight() {
        saveTask?.cancel()
        let kg = weightKg
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 550_000_000)
            guard !Task.isCancelled else { return }
            await persistWeightKg(kg)
        }
    }

    func persistWeightKg(_ kg: Double) async {
        do {
            try await dailyStatsService.saveTodayStats(userId: userId, weight: kg)
            try await db.collection("users").document(userId).updateData([
                "weight": kg,
                "updatedAt": Timestamp(date: Date())
            ])
            try? await refreshHistory()
            NotificationCenter.default.post(name: NSNotification.Name("WeightLogged"), object: nil)
        } catch {
            print("Weight save error: \(error.localizedDescription)")
        }
    }

    func saveGoalKg(_ kg: Double) async {
        goalWeightKg = kg
        do {
            try await db.collection("users").document(userId).updateData([
                "targetWeight": kg,
                "updatedAt": Timestamp(date: Date())
            ])
            NotificationCenter.default.post(name: NSNotification.Name("WeightLogged"), object: nil)
        } catch {
            print("Goal save error: \(error.localizedDescription)")
        }
    }

    /// Call from `onChange` after `displayUnit` was updated by the picker.
    func applyUnitChange(from old: WeightUnit, to newUnit: WeightUnit) {
        guard old != newUnit else { return }
        let kg = old.convert(rulerValue, to: .kg)
        rulerValue = min(
            max(WeightUnit.kg.convert(kg, to: newUnit), newUnit.range.lowerBound),
            newUnit.range.upperBound
        )
    }
}
