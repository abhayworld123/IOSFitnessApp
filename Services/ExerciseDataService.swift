import Foundation

struct ExerciseDataService {
    static func loadExercisesFromJSON() throws -> [Exercise] {
        // Try multiple paths to find the JSON file
        var url: URL?
        
        // Try 1: Bundle resource in Data subdirectory
        url = Bundle.main.url(forResource: "exercises", withExtension: "json", subdirectory: "Data")
        
        // Try 2: Bundle resource at root
        if url == nil {
            url = Bundle.main.url(forResource: "exercises", withExtension: "json")
        }
        
        // Try 3: Direct file path (for development)
        if url == nil {
            let fileManager = FileManager.default
            let currentPath = fileManager.currentDirectoryPath
            let possiblePaths = [
                "\(currentPath)/Data/exercises.json",
                "\(currentPath)/FitnessApp/Data/exercises.json",
                "/Users/abhaymac/Desktop/projects/FitnessApp/Data/exercises.json"
            ]
            
            for path in possiblePaths {
                if fileManager.fileExists(atPath: path) {
                    url = URL(fileURLWithPath: path)
                    break
                }
            }
        }
        
        guard let fileURL = url else {
            throw NSError(domain: "ExerciseDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "exercises.json file not found"])
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        
        // Create a wrapper struct to decode the JSON structure
        struct ExercisesWrapper: Codable {
            let exercises: [ExerciseJSON]
        }
        
        struct ExerciseJSON: Codable {
            let id: String
            let name: String
            let description: String
            let sets: Int?
            let reps: Int?
            let duration: Int?
            let restTime: Int
            let muscleGroups: [String]
            let difficultyLevel: String
            let videoURL: String?
            let instructions: [String]
            let category: String? // Not used in Exercise model, but present in JSON
        }
        
        let wrapper = try decoder.decode(ExercisesWrapper.self, from: data)
        
        // Convert JSON exercises to Exercise models
        return wrapper.exercises.map { jsonExercise in
            // Convert muscle group strings to enum
            let muscleGroups = jsonExercise.muscleGroups.compactMap { MuscleGroup(rawValue: $0) }
            
            // Convert difficulty level string to enum
            let difficulty: DifficultyLevel
            switch jsonExercise.difficultyLevel.lowercased() {
            case "beginner":
                difficulty = .beginner
            case "intermediate":
                difficulty = .intermediate
            case "advanced":
                difficulty = .advanced
            default:
                difficulty = .intermediate
            }
            
            return Exercise(
                id: jsonExercise.id,
                name: jsonExercise.name,
                description: jsonExercise.description,
                sets: jsonExercise.sets,
                reps: jsonExercise.reps,
                duration: jsonExercise.duration,
                restTime: jsonExercise.restTime,
                animationURL: jsonExercise.videoURL, // Map videoURL to animationURL
                muscleGroups: muscleGroups,
                difficultyLevel: difficulty,
                instructions: jsonExercise.instructions,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
}
