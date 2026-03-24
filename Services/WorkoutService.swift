import Foundation
import FirebaseFirestore

@MainActor
class WorkoutService: ObservableObject {
    static let shared = WorkoutService()
    
    private let db = Firestore.firestore()
    private let workoutsCollection = "workouts"
    private let exercisesCollection = "exercises"
    
    private init() {}
    
    // MARK: - Workout Operations
    
    func fetchWorkouts() async throws -> [Workout] {
        let snapshot = try await db.collection(workoutsCollection)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        var workouts: [Workout] = []
        for document in snapshot.documents {
            if let workout = try? Firestore.Decoder().decode(Workout.self, from: document.data()) {
                workouts.append(workout)
            }
        }
        return workouts
    }
    
    func fetchUserWorkouts(userId: String) async throws -> [Workout] {
        let snapshot = try await db.collection(workoutsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var workouts: [Workout] = []
        for document in snapshot.documents {
            if let workout = try? Firestore.Decoder().decode(Workout.self, from: document.data()) {
                workouts.append(workout)
            }
        }
        return workouts
    }
    
    /// Template / "How To" workouts (no userId — app-provided content only).
    func fetchTemplateWorkouts() async throws -> [Workout] {
        let all = try await fetchWorkouts()
        return all.filter { $0.userId == nil }
    }
    
    func fetchWorkout(id: String) async throws -> Workout? {
        let document = try await db.collection(workoutsCollection).document(id).getDocument()
        guard let data = document.data() else { return nil }
        return try Firestore.Decoder().decode(Workout.self, from: data)
    }
    
    func createWorkout(_ workout: Workout) async throws {
        let data = try Firestore.Encoder().encode(workout)
        try await db.collection(workoutsCollection).document(workout.id).setData(data)
    }
    
    func updateWorkout(_ workout: Workout) async throws {
        var data = try Firestore.Encoder().encode(workout)
        data["updatedAt"] = Timestamp(date: Date())
        try await db.collection(workoutsCollection).document(workout.id).updateData(data)
    }
    
    func deleteWorkout(id: String) async throws {
        try await db.collection(workoutsCollection).document(id).delete()
    }
    
    // MARK: - Filtering & Searching
    
    func filterWorkouts(_ workouts: [Workout], by category: WorkoutCategory) -> [Workout] {
        guard category != .all else { return workouts }
        return workouts.filter { $0.category == category }
    }
    
    func filterWorkouts(_ workouts: [Workout], by difficulty: DifficultyLevel) -> [Workout] {
        guard difficulty != .allLevels else { return workouts }
        return workouts.filter { $0.difficulty == difficulty }
    }
    
    func filterWorkouts(_ workouts: [Workout], isPremium: Bool?) -> [Workout] {
        guard let isPremium = isPremium else { return workouts }
        return workouts.filter { $0.isPremium == isPremium }
    }
    
    func searchWorkouts(_ workouts: [Workout], query: String) -> [Workout] {
        guard !query.isEmpty else { return workouts }
        let lowercasedQuery = query.lowercased()
        return workouts.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.description.lowercased().contains(lowercasedQuery) ||
            $0.category.displayName.lowercased().contains(lowercasedQuery)
        }
    }
    
    // MARK: - Exercise Operations
    
    func fetchExercise(id: String) async throws -> Exercise? {
        let document = try await db.collection(exercisesCollection).document(id).getDocument()
        guard let data = document.data() else { return nil }
        return try Firestore.Decoder().decode(Exercise.self, from: data)
    }
    
    func fetchExercises(ids: [String]) async throws -> [Exercise] {
        var exercises: [Exercise] = []
        for id in ids {
            if let exercise = try? await fetchExercise(id: id) {
                exercises.append(exercise)
            }
        }
        return exercises
    }
    
    func fetchAllExercises() async throws -> [Exercise] {
        let snapshot = try await db.collection(exercisesCollection)
            .order(by: "name", descending: false)
            .getDocuments()
        
        var exercises: [Exercise] = []
        for document in snapshot.documents {
            if let exercise = try? Firestore.Decoder().decode(Exercise.self, from: document.data()) {
                exercises.append(exercise)
            }
        }
        return exercises
    }
    
    func createExercise(_ exercise: Exercise) async throws {
        let data = try Firestore.Encoder().encode(exercise)
        try await db.collection(exercisesCollection).document(exercise.id).setData(data)
    }
    
    // MARK: - Batch Operations
    
    func seedSampleWorkouts() async throws {
        let sampleWorkouts = SampleData.workouts
        let batch = db.batch()
        
        for workout in sampleWorkouts {
            let data = try Firestore.Encoder().encode(workout)
            let ref = db.collection(workoutsCollection).document(workout.id)
            batch.setData(data, forDocument: ref)
        }
        
        try await batch.commit()
    }
    
    func seedExercisesFromJSON() async throws {
        // Load exercises from JSON
        let exercises = try ExerciseDataService.loadExercisesFromJSON()
        
        // Use batch writes (Firestore limit is 500 operations per batch)
        let batchSize = 500
        var currentBatch = db.batch()
        var operationCount = 0
        
        for (index, exercise) in exercises.enumerated() {
            // Check if exercise already exists
            let docRef = db.collection(exercisesCollection).document(exercise.id)
            
            // Use setData with merge to avoid overwriting existing exercises
            let data = try Firestore.Encoder().encode(exercise)
            currentBatch.setData(data, forDocument: docRef, merge: true)
            operationCount += 1
            
            // Commit batch if we've reached the limit or it's the last exercise
            if operationCount >= batchSize || index == exercises.count - 1 {
                try await currentBatch.commit()
                currentBatch = db.batch()
                operationCount = 0
            }
        }
        
        // Commit any remaining operations
        if operationCount > 0 {
            try await currentBatch.commit()
        }
    }
}

