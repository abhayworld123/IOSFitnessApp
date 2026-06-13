import Foundation

enum CategoryPlacementKey: String, Codable, CaseIterable {
    case workoutHome = "workout_home"
    case createWorkoutChip = "create_workout_chip"
    case videoLibraryFilter = "video_library_filter"
}

struct CategoryPlacementConfig: Codable, Equatable {
    var enabled: Bool?
    var label: String?
    var sortOrder: Int?
    var gradient: [String]?
    var exploreFilter: String?
}

struct CategoryConfig: Codable, Identifiable, Equatable {
    let id: String
    var workoutCategory: String?
    var imageURL: String?
    var sfSymbolFallback: String?
    var placements: [String: CategoryPlacementConfig]?

    var resolvedWorkoutCategory: WorkoutCategory? {
        guard let raw = workoutCategory?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return WorkoutCategory(rawValue: raw)
    }

    func placement(_ key: CategoryPlacementKey) -> CategoryPlacementConfig? {
        placements?[key.rawValue]
    }

    func isEnabled(for key: CategoryPlacementKey) -> Bool {
        placement(key)?.enabled ?? false
    }

    func label(for key: CategoryPlacementKey, fallback: String) -> String {
        let t = placement(key)?.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? fallback : t
    }

    func sortOrder(for key: CategoryPlacementKey) -> Int {
        placement(key)?.sortOrder ?? 999
    }

    func exploreFilterEnum() -> WorkoutHomeExploreFilter? {
        guard let raw = placement(.workoutHome)?.exploreFilter else { return nil }
        return WorkoutHomeExploreFilter.fromAPI(raw)
    }

    func gradientColors(for key: CategoryPlacementKey, fallback: [String]) -> [String] {
        guard let g = placement(key)?.gradient, !g.isEmpty else { return fallback }
        return g
    }

    var normalizedImageURL: URL? {
        guard let s = imageURL?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return URL(string: s)
    }
}

extension WorkoutHomeExploreFilter {
    static func fromAPI(_ raw: String) -> WorkoutHomeExploreFilter? {
        switch raw.lowercased() {
        case "build": return .build
        case "recovery": return .recovery
        case "maintain": return .maintain
        default: return nil
        }
    }
}

enum CategoryConfigFallback {
    static let workoutHome: [(filter: WorkoutHomeExploreFilter, title: String, gradient: [String], image: String?, sfSymbol: String)] = [
        (.maintain, "cardio", ["#FFE4CC", "#FFCCA8"], nil, "figure.run"),
        (.recovery, "yog", ["#D6E8FF", "#B8D4FF"], "yoga", "figure.yoga"),
        (.build, "boxing", ["#D4F0DD", "#A8E0B8"], nil, "figure.boxing"),
    ]

    static let createWorkoutChips: [(title: String, category: WorkoutCategory, asset: String?, sfSymbol: String)] = [
        ("Strength", .strength, "dumble", "dumbbell.fill"),
        ("Cardio", .cardio, nil, "figure.run"),
        ("Yoga", .yoga, "yoga", "figure.yoga"),
    ]
}
