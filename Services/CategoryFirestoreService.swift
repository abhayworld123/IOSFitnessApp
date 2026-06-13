import Foundation
import FirebaseFirestore

/// Reads category presentation docs written by exercise-video-admin (Firestore + R2 imageURL).
enum CategoryFirestoreService {
    private static let db = Firestore.firestore()

    static func fetchAllCategories() async throws -> [CategoryConfig] {
        let snap = try await db.collection(FirestoreCollections.categories).getDocuments()
        return snap.documents.compactMap { parseCategory(id: $0.documentID, data: $0.data()) }
            .sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
    }

    private static func parseCategory(id: String, data: [String: Any]) -> CategoryConfig? {
        let jsonReady = firestoreValueToJSON(data) as? [String: Any] ?? [:]
        var payload: [String: Any] = ["id": id]
        if let wc = jsonReady["workoutCategory"] {
            payload["workoutCategory"] = wc is NSNull ? NSNull() : wc
        }
        if let imageURL = jsonReady["imageURL"] as? String, !imageURL.isEmpty {
            payload["imageURL"] = imageURL
        }
        if let sf = jsonReady["sfSymbolFallback"] as? String {
            payload["sfSymbolFallback"] = sf
        }
        if let placements = jsonReady["placements"] as? [String: Any] {
            payload["placements"] = placements
        }
        guard JSONSerialization.isValidJSONObject(payload),
              let json = try? JSONSerialization.data(withJSONObject: payload) else {
            return nil
        }
        return try? JSONDecoder().decode(CategoryConfig.self, from: json)
    }

    /// Firestore field values (Int64, Timestamp, nested maps) → JSON-safe types.
    private static func firestoreValueToJSON(_ value: Any) -> Any {
        if let ts = value as? Timestamp {
            return ts.dateValue().timeIntervalSince1970
        }
        if let n = value as? Int64 {
            return Int(n)
        }
        if let n = value as? UInt64 {
            return Int(n)
        }
        if let dict = value as? [String: Any] {
            var out: [String: Any] = [:]
            for (k, v) in dict {
                out[k] = firestoreValueToJSON(v)
            }
            return out
        }
        if let arr = value as? [Any] {
            return arr.map { firestoreValueToJSON($0) }
        }
        return value
    }
}
