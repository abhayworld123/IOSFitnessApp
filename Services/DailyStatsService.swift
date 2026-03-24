import Foundation
import FirebaseFirestore

@MainActor
class DailyStatsService: ObservableObject {
    static let shared = DailyStatsService()

    private let db = Firestore.firestore()
    private let dailyStatsCollection = "dailyStats"

    private init() {}

    // MARK: - Save (merge so we don't overwrite other fields)

    func saveDailyStats(userId: String, stats: UserDailyStats) async throws {
        let ref = db.collection("users").document(userId).collection(dailyStatsCollection).document(stats.dateString)
        var data: [String: Any] = [
            "dateString": stats.dateString,
            "date": Timestamp(date: stats.date),
            "steps": stats.steps,
            "stepsGoal": stats.stepsGoal,
            "sleep": stats.sleep,
            "sleepGoal": stats.sleepGoal,
            "createdAt": Timestamp(date: stats.createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
        if let weight = stats.weight {
            data["weight"] = weight
        }
        try await ref.setData(data, merge: true)
    }

    /// Merge-only update for today's doc (creates or updates fields).
    func saveTodayStats(userId: String, steps: Int? = nil, stepsGoal: Int? = nil, sleep: Double? = nil, sleepGoal: Double? = nil, weight: Double? = nil) async throws {
        let now = Date()
        let dateString = UserDailyStats.dateString(for: now)
        let ref = db.collection("users").document(userId).collection(dailyStatsCollection).document(dateString)

        var stats: UserDailyStats
        if let existing = try await fetchDailyStats(userId: userId, date: now) {
            stats = existing
            if let v = steps { stats.steps = v }
            if let v = stepsGoal { stats.stepsGoal = v }
            if let v = sleep { stats.sleep = v }
            if let v = sleepGoal { stats.sleepGoal = v }
            if let v = weight { stats.weight = v }
        } else {
            stats = UserDailyStats(
                dateString: dateString,
                date: now,
                steps: steps ?? 0,
                stepsGoal: stepsGoal ?? 10_000,
                sleep: sleep ?? 0,
                sleepGoal: sleepGoal ?? 7,
                weight: weight
            )
        }
        stats.updatedAt = now
        try await saveDailyStats(userId: userId, stats: stats)
    }

    // MARK: - Fetch one day

    func fetchDailyStats(userId: String, date: Date) async throws -> UserDailyStats? {
        let dateString = UserDailyStats.dateString(for: date)
        let ref = db.collection("users").document(userId).collection(dailyStatsCollection).document(dateString)
        let snap = try await ref.getDocument()
        guard snap.exists, let d = snap.data() else { return nil }
        return decodeDailyStats(from: d, dateString: dateString)
    }

    // MARK: - Fetch month range

    func fetchMonthlyDailyStats(userId: String, startDate: Date, endDate: Date) async throws -> [UserDailyStats] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endDate))!

        let snapshot = try await db.collection("users").document(userId).collection(dailyStatsCollection)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .order(by: "date", descending: false)
            .getDocuments()

        var result: [UserDailyStats] = []
        for doc in snapshot.documents {
            var data = doc.data()
            if let date = data["date"] as? Timestamp {
                data["date"] = date.dateValue()
            }
            if let createdAt = data["createdAt"] as? Timestamp {
                data["createdAt"] = createdAt.dateValue()
            }
            if let updatedAt = data["updatedAt"] as? Timestamp {
                data["updatedAt"] = updatedAt.dateValue()
            }
            if let stats = decodeDailyStats(from: data, dateString: doc.documentID) {
                result.append(stats)
            }
        }
        return result
    }

    /// Days with a non-nil weight, sorted by date ascending (for charts).
    func fetchWeightHistory(userId: String, daysBack: Int = 120) async throws -> [(date: Date, weightKg: Double)] {
        let cal = Calendar.current
        let end = Date()
        let start = cal.date(byAdding: .day, value: -daysBack, to: cal.startOfDay(for: end)) ?? end
        let stats = try await fetchMonthlyDailyStats(userId: userId, startDate: start, endDate: end)
        return stats.compactMap { s -> (Date, Double)? in
            guard let w = s.weight else { return nil }
            return (s.date, w)
        }
    }

    private func decodeDailyStats(from data: [String: Any], dateString id: String) -> UserDailyStats? {
        var d = data
        d["dateString"] = id
        if let date = d["date"] as? Timestamp {
            d["date"] = date.dateValue()
        }
        if let createdAt = d["createdAt"] as? Timestamp {
            d["createdAt"] = createdAt.dateValue()
        }
        if let updatedAt = d["updatedAt"] as? Timestamp {
            d["updatedAt"] = updatedAt.dateValue()
        }
        return try? Firestore.Decoder().decode(UserDailyStats.self, from: d)
    }
}
