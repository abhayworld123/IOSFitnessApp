import Foundation
import FirebaseFirestore

@MainActor
final class WeightTrackingViewModel: ObservableObject {
    let userId: String

    @Published var displayUnit: WeightUnit = .kg
    @Published var rulerValue: Double = 70
    @Published var goalWeightKg: Double?
    @Published var history: [(date: Date, weightKg: Double)] = []
    /// Set when the user stops sliding the empty-state ruler; drives the big readout.
    @Published private(set) var emptySelectedWeight: Double?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let dailyStatsService = DailyStatsService.shared
    private var saveTask: Task<Void, Never>?

    init(userId: String) {
        self.userId = userId
    }

    var weightKg: Double {
        displayUnit.convert(rulerValue, to: .kg)
    }

    /// No weight logs in daily stats yet — show onboarding-style empty screen.
    var isEmptyTrackingState: Bool {
        history.isEmpty
    }

    /// Big number on empty card — `00.00` until the ruler slide settles, then the picked weight.
    var emptyDisplayWeightText: String {
        guard let w = emptySelectedWeight else { return "00.00" }
        return String(format: "%.2f", w)
    }

    func commitEmptyRulerSelection() {
        emptySelectedWeight = rulerValue
    }

    static func emptyDefaultRulerValue(for unit: WeightUnit) -> Double {
        unit == .kg ? 75.0 : 165.0
    }

    /// ±2.5 kg band around goal for the “ideal weight” fill (kg).
    var idealBandKg: (low: Double, high: Double)? {
        guard let g = goalWeightKg else { return nil }
        return (g - 2.5, g + 2.5)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let doc = try await db.collection(FirestoreCollections.users).document(userId).getDocument()
            let data = doc.data() ?? [:]

            if let g = data["targetWeight"] as? Double {
                goalWeightKg = g
            } else {
                goalWeightKg = nil
            }

            if let prefRaw = data[FirestoreFields.weightUnitPreference] as? String,
               let pref = WeightUnit(rawValue: prefRaw) {
                displayUnit = pref
            }

            try? await refreshHistory()

            if let last = history.last {
                rulerValue = WeightUnit.kg.convert(last.weightKg, to: displayUnit)
            } else if let wKg = data[FirestoreFields.weight] as? Double, wKg > 0 {
                emptySelectedWeight = nil
                rulerValue = WeightUnit.kg.convert(wKg, to: displayUnit)
            } else {
                emptySelectedWeight = nil
                rulerValue = Self.emptyDefaultRulerValue(for: displayUnit)
            }
        } catch {
            errorMessage = "Failed to load weight data. Please try again."
            rulerValue = displayUnit.defaultValue
        }
    }

    func refreshHistory() async throws {
        let entries = try await dailyStatsService.fetchWeightHistory(userId: userId, daysBack: 120)
        history = entries.sorted { $0.date < $1.date }
    }

    func schedulePersistWeight() {
        guard !isEmptyTrackingState else { return }
        saveTask?.cancel()
        let kg = weightKg
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 550_000_000)
            guard !Task.isCancelled else { return }
            await persistWeightKg(kg)
        }
    }

    /// Saves the current ruler value immediately (for “Add First log” / “Add New log”).
    func addLogNow() async {
        saveTask?.cancel()
        await persistWeightKg(weightKg)
    }

    func persistWeightKg(_ kg: Double) async {
        do {
            try await dailyStatsService.saveTodayStats(userId: userId, weight: kg)
            try await db.collection(FirestoreCollections.users).document(userId).updateData([
                FirestoreFields.weight: kg,
                FirestoreFields.updatedAt: Timestamp(date: Date())
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
            try await db.collection(FirestoreCollections.users).document(userId).updateData([
                "targetWeight": kg,
                FirestoreFields.updatedAt: Timestamp(date: Date())
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
        if let selected = emptySelectedWeight {
            let selectedKg = old.convert(selected, to: .kg)
            emptySelectedWeight = WeightUnit.kg.convert(selectedKg, to: newUnit)
        }
    }

    // MARK: - Progress (last 6 months)

    /// Change in kg from the start to the end of the 6‑month window (negative = loss).
    var trendDeltaKg: Double {
        let bars = sixMonthBarsInternal()
        guard let first = bars.first?.weightKg, let last = bars.last?.weightKg else { return 0 }
        return last - first
    }

    /// One value per month for the last 6 calendar months (carried forward when no log).
    func sixMonthBars() -> [WeightMonthBar] {
        sixMonthBarsInternal()
    }

    /// “Ideal” reference line in the mock (slightly above goal).
    var idealWeightKg: Double? {
        guard let g = goalWeightKg else { return nil }
        return g + 2.0
    }

    private func sixMonthBarsInternal() -> [WeightMonthBar] {
        let cal = Calendar.current
        guard let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date())) else {
            return []
        }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        /// `MMM` avoids ambiguous two-letter collisions (e.g. March vs May both “MA” with `LLL`).
        df.dateFormat = "MMM"
        var months: [Date] = []
        for i in 0..<6 {
            guard let m = cal.date(byAdding: .month, value: -5 + i, to: thisMonthStart) else { continue }
            months.append(m)
        }
        guard let firstMonth = months.first else { return [] }
        let beforeFirst = history.filter { $0.date < firstMonth }.sorted { $0.date < $1.date }
        var lastCarried = beforeFirst.last?.weightKg ?? max(0, weightKg)
        var out: [WeightMonthBar] = []
        for m in months {
            let end = cal.date(byAdding: .month, value: 1, to: m) ?? m
            let inMonth = history.filter { $0.date >= m && $0.date < end }.sorted { $0.date < $1.date }
            let w = inMonth.last?.weightKg ?? lastCarried
            lastCarried = w
            let label = df.string(from: m).uppercased()
            let id = ISO8601DateFormatter().string(from: m)
            out.append(WeightMonthBar(id: id, monthStart: m, label: label, weightKg: w))
        }
        return out
    }
}

// MARK: - Month bar (chart)

struct WeightMonthBar: Identifiable {
    let id: String
    let monthStart: Date
    let label: String
    let weightKg: Double
}
