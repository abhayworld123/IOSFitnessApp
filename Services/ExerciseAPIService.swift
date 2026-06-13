import Foundation

/// Reads exercise catalog from the exercise-video-admin HTTP API when configured via Info.plist.
enum ExerciseAPIConfiguration {
    /// Base URL without trailing slash, e.g. `https://api.example.com`
    static var baseURL: URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "ExerciseAPIBaseURL") as? String else { return nil }
        var trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        while trimmed.hasSuffix("/") {
            trimmed = String(trimmed.dropLast())
        }
        return URL(string: trimmed)
    }

    /// Optional `PUBLIC_API_KEY` — sent as `X-App-Key`.
    static var publicAPIKey: String? {
        let s = Bundle.main.object(forInfoDictionaryKey: "ExerciseAPIPublicKey") as? String
        let t = s?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? nil : t
    }

    static var isConfigured: Bool { baseURL != nil }

    /// Base URL for Aura coach chat. Falls back to `ExerciseAPIBaseURL`.
    /// Set `ExerciseAPIChatBaseURL` to a direct Cloud Function URL if Hosting POST requests drop on simulator.
    static var chatBaseURL: URL? {
        normalizedURL(fromInfoKey: "ExerciseAPIChatBaseURL") ?? baseURL
    }

    private static func normalizedURL(fromInfoKey key: String) -> URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        var trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        while trimmed.hasSuffix("/") {
            trimmed = String(trimmed.dropLast())
        }
        return URL(string: trimmed)
    }
}

enum ExerciseCatalogMerge {
    /// Preserves `ids` order. Video URL: API, then Firestore, then JSON. Base record prefers API, then Firestore, then JSON.
    static func mergedOrdered(
        ids: [String],
        api: [Exercise],
        firestore: [Exercise],
        json: [Exercise]
    ) -> [Exercise] {
        let apiD = Dictionary(uniqueKeysWithValues: api.map { ($0.id, $0) })
        let fsD = Dictionary(uniqueKeysWithValues: firestore.map { ($0.id, $0) })
        let jD = Dictionary(uniqueKeysWithValues: json.map { ($0.id, $0) })

        return ids.compactMap { id in
            mergeOne(id: id, api: apiD[id], firestore: fsD[id], json: jD[id])
        }
    }

    static func mergeOne(id: String, api: Exercise?, firestore: Exercise?, json: Exercise?) -> Exercise? {
        guard var merged = api ?? firestore ?? json else { return nil }

        let anim =
            normalizedURL(api?.animationURL)
            ?? normalizedURL(firestore?.animationURL)
            ?? normalizedURL(json?.animationURL)
        merged.animationURL = anim

        let thumb =
            normalizedURL(api?.thumbnailURL)
            ?? normalizedURL(firestore?.thumbnailURL)
            ?? normalizedURL(json?.thumbnailURL)
        merged.thumbnailURL = thumb

        if merged.name.isEmpty {
            merged.name = firestore?.name ?? json?.name ?? ""
        }
        if merged.description.isEmpty {
            merged.description = firestore?.description ?? json?.description ?? ""
        }
        if merged.instructions.isEmpty {
            merged.instructions = firestore?.instructions ?? json?.instructions ?? []
        }
        if merged.muscleGroups.isEmpty {
            merged.muscleGroups = firestore?.muscleGroups ?? json?.muscleGroups ?? [.fullBody]
        }

        return merged
    }

    private static func normalizedURL(_ s: String?) -> String? {
        guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        return t
    }

    /// Full catalog: merge by id; API rows win on conflict, then Firestore, then JSON for missing ids.
    static func mergedAllCatalog(api: [Exercise], firestore: [Exercise], json: [Exercise]) -> [Exercise] {
        let jsonD = Dictionary(uniqueKeysWithValues: json.map { ($0.id, $0) })
        var dict = Dictionary(uniqueKeysWithValues: firestore.map { ($0.id, $0) })
        for (jid, j) in jsonD where dict[jid] == nil { dict[jid] = j }
        for e in api {
            dict[e.id] = mergeOne(id: e.id, api: e, firestore: dict[e.id], json: jsonD[e.id]) ?? e
        }
        return dict.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

struct ExerciseAPIService {
    static let shared = ExerciseAPIService()

    private init() {}

    func fetchAllExercises() async throws -> [Exercise] {
        guard let base = ExerciseAPIConfiguration.baseURL else {
            throw ExerciseAPIError.notConfigured
        }
        let url = base.appendingPathComponent("api/v1/exercises")
        var request = ExerciseAPIHTTPClient.preparedRequest(url: url)
        addAppKey(to: &request)
        let (data, response) = try await ExerciseAPIHTTPClient.data(for: request)
        try validate(response: response, data: data)
        return try decodeList(data)
    }

    func fetchExercises(ids: [String]) async throws -> [Exercise] {
        guard let base = ExerciseAPIConfiguration.baseURL else {
            throw ExerciseAPIError.notConfigured
        }
        let url = base.appendingPathComponent("api/v1/exercises/by-ids")
        var request = ExerciseAPIHTTPClient.preparedRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAppKey(to: &request)
        let body = ["ids": ids]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await ExerciseAPIHTTPClient.data(for: request)
        try validate(response: response, data: data)
        return try decodeList(data)
    }

    private func addAppKey(to request: inout URLRequest) {
        if let key = ExerciseAPIConfiguration.publicAPIKey {
            request.setValue(key, forHTTPHeaderField: "X-App-Key")
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ExerciseAPIError.http(http.statusCode, msg)
        }
    }

    private func decodeList(_ data: Data) throws -> [Exercise] {
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ExercisesListResponse.self, from: data)
        return wrapper.exercises.map { $0.toExercise() }
    }
}

private enum ExerciseAPIError: Error {
    case notConfigured
    case http(Int, String)
}

private struct ExercisesListResponse: Decodable {
    let exercises: [ExerciseDTO]
}

private struct ExerciseDTO: Decodable {
    let id: String
    let name: String?
    let description: String?
    let sets: Int?
    let reps: Int?
    let duration: Int?
    let restTime: Int?
    let animationURL: String?
    let videoURL: String?
    let thumbnailURL: String?
    let muscleGroups: [String]?
    let difficultyLevel: String?
    let instructions: [String]?
    let createdAt: FlexibleDate?
    let updatedAt: FlexibleDate?

    func toExercise() -> Exercise {
        let muscle = (muscleGroups ?? []).compactMap { MuscleGroup(rawValue: $0) }
        let difficulty: DifficultyLevel
        switch (difficultyLevel ?? "intermediate").lowercased() {
        case "beginner": difficulty = .beginner
        case "intermediate": difficulty = .intermediate
        case "advanced": difficulty = .advanced
        case "alllevels": difficulty = .allLevels
        default: difficulty = .intermediate
        }
        let rest = restTime ?? 30
        let anim = animationURL ?? videoURL
        let thumbTrimmed: String? = {
            guard let t = thumbnailURL?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
            return t
        }()
        let created = createdAt?.date ?? Date()
        let updated = updatedAt?.date ?? Date()
        return Exercise(
            id: id,
            name: name ?? "",
            description: description ?? "",
            sets: sets,
            reps: reps,
            duration: duration,
            restTime: rest,
            animationURL: anim,
            thumbnailURL: thumbTrimmed,
            muscleGroups: muscle.isEmpty ? [.fullBody] : muscle,
            difficultyLevel: difficulty,
            instructions: instructions ?? [],
            createdAt: created,
            updatedAt: updated
        )
    }
}

private struct FlexibleDate: Decodable {
    let date: Date?

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let t = try? c.decode(Double.self) {
            date = Date(timeIntervalSince1970: t)
            return
        }
        if let s = try? c.decode(String.self) {
            date = FlexibleDate.parseISO8601(s)
            return
        }
        date = nil
    }

    private static func parseISO8601(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }
}
