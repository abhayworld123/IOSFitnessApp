import Foundation
import FirebaseFirestore

@MainActor
class ExerciseLogService: ObservableObject {
    static let shared = ExerciseLogService()
    
    private let db = Firestore.firestore()
    private let exerciseLogsCollection = "exerciseLogs"
    
    private init() {}
    
    // MARK: - Fetch Exercise Logs
    
    func fetchExerciseLog(exerciseId: String, workoutId: String, userId: String) async throws -> ExerciseLog? {
        let snapshot = try await db.collection(exerciseLogsCollection)
            .whereField("exerciseId", isEqualTo: exerciseId)
            .whereField("workoutId", isEqualTo: workoutId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        var data = document.data()
        // Convert Firestore Timestamps to Dates
        if let date = data["date"] as? Timestamp {
            data["date"] = date.dateValue()
        }
        if let createdAt = data["createdAt"] as? Timestamp {
            data["createdAt"] = createdAt.dateValue()
        }
        if let updatedAt = data["updatedAt"] as? Timestamp {
            data["updatedAt"] = updatedAt.dateValue()
        }
        
        // Convert sets array
        if let setsData = data["sets"] as? [[String: Any]] {
            var sets: [ExerciseSet] = []
            for setData in setsData {
                var setDict = setData
                if let completedAt = setData["completedAt"] as? Timestamp {
                    setDict["completedAt"] = completedAt.dateValue()
                }
                if let set = try? Firestore.Decoder().decode(ExerciseSet.self, from: setDict) {
                    sets.append(set)
                }
            }
            data["sets"] = sets
        }
        
        return try Firestore.Decoder().decode(ExerciseLog.self, from: data)
    }
    
    // MARK: - Save Exercise Log
    
    func saveExerciseLog(_ log: ExerciseLog) async throws {
        var data = try Firestore.Encoder().encode(log)
        
        // Convert Date to Timestamp for Firestore
        data["date"] = Timestamp(date: log.date)
        data["createdAt"] = Timestamp(date: log.createdAt)
        data["updatedAt"] = Timestamp(date: log.updatedAt)
        
        // Convert sets array with timestamps
        var setsData: [[String: Any]] = []
        for set in log.sets {
            var setDict = try Firestore.Encoder().encode(set)
            if let completedAt = set.completedAt {
                setDict["completedAt"] = Timestamp(date: completedAt)
            }
            setsData.append(setDict)
        }
        data["sets"] = setsData
        
        try await db.collection(exerciseLogsCollection).document(log.id).setData(data, merge: true)
    }
    
    // MARK: - Delete Exercise Log
    
    func deleteExerciseLog(_ logId: String) async throws {
        try await db.collection(exerciseLogsCollection).document(logId).delete()
    }
    
    // MARK: - Fetch All Logs for Exercise
    
    func fetchAllLogsForExercise(exerciseId: String, userId: String) async throws -> [ExerciseLog] {
        let snapshot = try await db.collection(exerciseLogsCollection)
            .whereField("exerciseId", isEqualTo: exerciseId)
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        var logs: [ExerciseLog] = []
        for document in snapshot.documents {
            var data = document.data()
            // Convert Firestore Timestamps to Dates
            if let date = data["date"] as? Timestamp {
                data["date"] = date.dateValue()
            }
            if let createdAt = data["createdAt"] as? Timestamp {
                data["createdAt"] = createdAt.dateValue()
            }
            if let updatedAt = data["updatedAt"] as? Timestamp {
                data["updatedAt"] = updatedAt.dateValue()
            }
            
            // Convert sets array
            if let setsData = data["sets"] as? [[String: Any]] {
                var sets: [ExerciseSet] = []
                for setData in setsData {
                    var setDict = setData
                    if let completedAt = setData["completedAt"] as? Timestamp {
                        setDict["completedAt"] = completedAt.dateValue()
                    }
                    if let set = try? Firestore.Decoder().decode(ExerciseSet.self, from: setDict) {
                        sets.append(set)
                    }
                }
                data["sets"] = sets
            }
            
            if let log = try? Firestore.Decoder().decode(ExerciseLog.self, from: data) {
                logs.append(log)
            }
        }
        return logs
    }
}
