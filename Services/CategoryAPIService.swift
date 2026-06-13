import Foundation

@MainActor
final class CategoryConfigStore: ObservableObject {
    static let shared = CategoryConfigStore()

    @Published private(set) var categories: [CategoryConfig] = []
    @Published private(set) var isLoaded = false
    @Published private(set) var loadFailed = false

    private var loadTask: Task<Void, Never>?

    private init() {
        if let cached = CategoryDiskCache.loadCategories(), !cached.isEmpty {
            categories = cached
            isLoaded = true
            loadFailed = false
        }
    }

    func categories(for placement: CategoryPlacementKey) -> [CategoryConfig] {
        categories
            .filter { $0.isEnabled(for: placement) }
            .sorted { $0.sortOrder(for: placement) < $1.sortOrder(for: placement) }
    }

    func category(matching workoutCategory: WorkoutCategory, placement: CategoryPlacementKey) -> CategoryConfig? {
        categories(for: placement).first { $0.resolvedWorkoutCategory == workoutCategory }
    }

    func category(byId id: String) -> CategoryConfig? {
        categories.first { $0.id == id }
    }

    func imageURL(forCategoryId id: String) -> URL? {
        category(byId: id)?.normalizedImageURL
    }

    func ensureLoaded() {
        guard loadTask == nil else { return }
        loadTask = Task {
            await reload()
            loadTask = nil
        }
    }

    func reload() async {
        var firestoreList: [CategoryConfig] = []
        var apiList: [CategoryConfig] = []
        var firestoreError: Error?
        var apiError: Error?

        async let firestoreTask: [CategoryConfig] = {
            do {
                return try await CategoryFirestoreService.fetchAllCategories()
            } catch {
                firestoreError = error
                return []
            }
        }()

        async let apiTask: [CategoryConfig] = {
            guard ExerciseAPIConfiguration.isConfigured else { return [] }
            do {
                return try await CategoryAPIService.shared.fetchCategories()
            } catch {
                apiError = error
                return []
            }
        }()

        firestoreList = await firestoreTask
        apiList = await apiTask

        let fresh = mergeCategories(primary: apiList, fallback: firestoreList)

        if !fresh.isEmpty {
            categories = fresh
            loadFailed = false
            CategoryDiskCache.saveCategories(fresh)
            let imageURLs = fresh.compactMap(\.normalizedImageURL)
            CategoryImageCache.shared.prefetch(urls: imageURLs)
        } else if categories.isEmpty {
            loadFailed = true
        } else {
            // Network failed but disk cache still has last good config.
            loadFailed = false
        }

        isLoaded = true

        #if DEBUG
        if fresh.isEmpty && categories.isEmpty {
            if let firestoreError { print("[CategoryConfigStore] Firestore failed:", firestoreError.localizedDescription) }
            if let apiError { print("[CategoryConfigStore] API failed:", apiError.localizedDescription) }
        } else {
            let source: String
            if !apiList.isEmpty { source = "API" }
            else if !firestoreList.isEmpty { source = "Firestore" }
            else { source = "disk cache" }
            let withImages = categories.filter { $0.normalizedImageURL != nil }.map(\.id)
            print("[CategoryConfigStore] \(categories.count) categories (\(source)), images:", withImages)
        }
        #endif
    }

    /// Prefer API ordering/content; fill missing imageURL/placements from Firestore.
    private func mergeCategories(primary api: [CategoryConfig], fallback firestore: [CategoryConfig]) -> [CategoryConfig] {
        if api.isEmpty { return firestore }
        if firestore.isEmpty { return api }
        let fsById = Dictionary(uniqueKeysWithValues: firestore.map { ($0.id, $0) })
        return api.map { cat in
            guard let fs = fsById[cat.id] else { return cat }
            var merged = cat
            if merged.normalizedImageURL == nil, let url = fs.imageURL {
                merged.imageURL = url
            }
            if merged.placements == nil || merged.placements?.isEmpty == true {
                merged.placements = fs.placements
            }
            return merged
        }
    }
}

struct CategoryAPIService {
    static let shared = CategoryAPIService()

    private init() {}

    func fetchCategories(placement: CategoryPlacementKey? = nil) async throws -> [CategoryConfig] {
        guard let base = ExerciseAPIConfiguration.baseURL else {
            throw CategoryAPIError.notConfigured
        }
        var components = URLComponents(
            url: base.appendingPathComponent("api/v1/categories"),
            resolvingAgainstBaseURL: false
        )
        if let placement {
            components?.queryItems = [URLQueryItem(name: "placement", value: placement.rawValue)]
        }
        guard let url = components?.url else {
            throw CategoryAPIError.notConfigured
        }
        var request = ExerciseAPIHTTPClient.preparedRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        addAppKey(to: &request)
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
            throw CategoryAPIError.http(http.statusCode, msg)
        }
    }

    private func decodeList(_ data: Data) throws -> [CategoryConfig] {
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(CategoriesListResponse.self, from: data)
        return wrapper.categories
    }
}

private enum CategoryAPIError: Error {
    case notConfigured
    case http(Int, String)
}

private struct CategoriesListResponse: Decodable {
    let categories: [CategoryConfig]
}
