import Foundation
import FirebaseFirestore

@MainActor
class WaterTrackingService: ObservableObject {
    static let shared = WaterTrackingService()
    
    private let db = Firestore.firestore()
    private let waterIntakeCollection = "waterIntake"
    private let waterRemindersCollection = "waterReminders"
    
    private init() {}
    
    // MARK: - Fetch Today's Intake
    
    func fetchTodayIntake(userId: String, date: Date = Date()) async throws -> WaterIntakeRecord? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let snapshot = try await db.collection(waterIntakeCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        var data = document.data()
        if let date = data["date"] as? Timestamp {
            data["date"] = date.dateValue()
        }
        if let createdAt = data["createdAt"] as? Timestamp {
            data["createdAt"] = createdAt.dateValue()
        }
        if let updatedAt = data["updatedAt"] as? Timestamp {
            data["updatedAt"] = updatedAt.dateValue()
        }
        
        return try Firestore.Decoder().decode(WaterIntakeRecord.self, from: data)
    }
    
    // MARK: - Fetch Weekly Data
    
    func fetchWeeklyData(userId: String, startDate: Date, endDate: Date) async throws -> [WaterIntakeRecord] {
        let snapshot = try await db.collection(waterIntakeCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: false)
            .getDocuments()
        
        var intakes: [WaterIntakeRecord] = []
        for document in snapshot.documents {
            var data = document.data()
            if let date = data["date"] as? Timestamp {
                data["date"] = date.dateValue()
            }
            if let createdAt = data["createdAt"] as? Timestamp {
                data["createdAt"] = createdAt.dateValue()
            }
            if let updatedAt = data["updatedAt"] as? Timestamp {
                data["updatedAt"] = updatedAt.dateValue()
            }
            
            if let intake = try? Firestore.Decoder().decode(WaterIntakeRecord.self, from: data) {
                intakes.append(intake)
            }
        }
        return intakes
    }
    
    // MARK: - Save Intake
    
    func saveIntake(_ intake: WaterIntakeRecord) async throws {
        var data = try Firestore.Encoder().encode(intake)
        data["date"] = Timestamp(date: intake.date)
        data["createdAt"] = Timestamp(date: intake.createdAt)
        data["updatedAt"] = Timestamp(date: intake.updatedAt)
        
        try await db.collection(waterIntakeCollection).document(intake.id).setData(data, merge: true)
    }
    
    // MARK: - Fetch Reminder
    
    func fetchReminder(userId: String) async throws -> WaterReminder? {
        let snapshot = try await db.collection(waterRemindersCollection)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        var data = document.data()
        if let createdAt = data["createdAt"] as? Timestamp {
            data["createdAt"] = createdAt.dateValue()
        }
        if let updatedAt = data["updatedAt"] as? Timestamp {
            data["updatedAt"] = updatedAt.dateValue()
        }
        
        // Handle reminderTimes array
        if let times = data["reminderTimes"] as? [Timestamp] {
            data["reminderTimes"] = times.map { $0.dateValue() }
        }
        
        return try Firestore.Decoder().decode(WaterReminder.self, from: data)
    }
    
    // MARK: - Save Reminder
    
    func saveReminder(_ reminder: WaterReminder) async throws {
        var data = try Firestore.Encoder().encode(reminder)
        data["createdAt"] = Timestamp(date: reminder.createdAt)
        data["updatedAt"] = Timestamp(date: reminder.updatedAt)
        
        // Convert reminderTimes to Timestamps
        data["reminderTimes"] = reminder.reminderTimes.map { Timestamp(date: $0) }
        
        try await db.collection(waterRemindersCollection).document(reminder.id).setData(data, merge: true)
    }
}
