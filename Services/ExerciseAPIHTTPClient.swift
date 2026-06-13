import Foundation

/// Shared URLSession for exercise-video-admin API with retries for transient simulator/network errors.
enum ExerciseAPIHTTPClient {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 2
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 24 * 1024 * 1024,
            diskCapacity: 128 * 1024 * 1024
        )
        return URLSession(configuration: config)
    }()

    /// Prefer HTTP/2 over QUIC — simulator often fails HTTP/3 with -1017 / -1005.
    static func preparedRequest(
        url: URL,
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 60
    ) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy)
        request.timeoutInterval = timeout
        request.httpShouldUsePipelining = false
        if #available(iOS 15.0, *) {
            request.assumesHTTP3Capable = false
        }
        return request
    }

    /// Join base URL + path without RFC relative-URL bugs (e.g. base ending in `/api`).
    static func apiURL(path: String, base: URL) -> URL? {
        var baseString = base.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        while baseString.hasSuffix("/") {
            baseString.removeLast()
        }
        var cleaned = path.trimmingCharacters(in: .whitespacesAndNewlines)
        while cleaned.hasPrefix("/") {
            cleaned.removeFirst()
        }
        guard !cleaned.isEmpty else { return URL(string: baseString) }
        return URL(string: "\(baseString)/\(cleaned)")
    }

    static func data(for request: URLRequest, maxAttempts: Int = 5) async throws -> (Data, URLResponse) {
        try await perform(
            request: request,
            maxAttempts: maxAttempts,
            longRunning: false
        )
    }

    /// For AI chat and other slow POSTs — fresh ephemeral session per attempt avoids HTTP/2 stream reuse bugs on simulator.
    static func longRunningData(for request: URLRequest, maxAttempts: Int = 4) async throws -> (Data, URLResponse) {
        try await perform(
            request: request,
            maxAttempts: maxAttempts,
            longRunning: true
        )
    }

    private static func perform(
        request: URLRequest,
        maxAttempts: Int,
        longRunning: Bool
    ) async throws -> (Data, URLResponse) {
        var lastError: Error?
        let postBody = request.httpBody

        for attempt in 0..<maxAttempts {
            if attempt > 0 {
                let delayNs = UInt64(attempt) * (longRunning ? 1_500_000_000 : 800_000_000)
                try await Task.sleep(nanoseconds: delayNs)
            }

            var mutable = request
            if #available(iOS 15.0, *) {
                mutable.assumesHTTP3Capable = false
            }
            mutable.httpShouldUsePipelining = false
            if longRunning {
                mutable.timeoutInterval = max(mutable.timeoutInterval, 120)
                mutable.cachePolicy = .reloadIgnoringLocalCacheData
                if postBody != nil {
                    mutable.httpBody = postBody
                }
            }

            do {
                if longRunning {
                    return try await dataWithEphemeralSession(mutable, postBody: postBody)
                }
                return try await session.data(for: mutable)
            } catch {
                lastError = error
                guard isRetryable(error), attempt < maxAttempts - 1 else { throw error }
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    private static func dataWithEphemeralSession(
        _ request: URLRequest,
        postBody: Data?
    ) async throws -> (Data, URLResponse) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 1
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        config.httpShouldUsePipelining = false

        let session = URLSession(configuration: config)
        defer { session.finishTasksAndInvalidate() }

        if let postBody, request.httpMethod?.uppercased() == "POST" {
            return try await session.upload(for: request, from: postBody)
        }
        return try await session.data(for: request)
    }

    static func isRetryable(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .networkConnectionLost,
             .timedOut,
             .cannotConnectToHost,
             .notConnectedToInternet,
             .cannotParseResponse,
             .dnsLookupFailed,
             .secureConnectionFailed,
             .dataNotAllowed,
             .cannotLoadFromNetwork:
            return true
        default:
            return false
        }
    }
}
