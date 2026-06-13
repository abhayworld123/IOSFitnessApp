import Foundation
import UIKit

/// Persists category metadata + images so Workout Home cards survive simulator QUIC drops.
enum CategoryDiskCache {
    private static let configFileName = "workout-categories.json"
    private static let imagesFolderName = "category-images"

    private static var cacheRoot: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("CategoryDiskCache", isDirectory: true)
    }

    private static var configURL: URL {
        cacheRoot.appendingPathComponent(configFileName)
    }

    private static var imagesDirectory: URL {
        cacheRoot.appendingPathComponent(imagesFolderName, isDirectory: true)
    }

    static func loadCategories() -> [CategoryConfig]? {
        ensureDirectories()
        guard let data = try? Data(contentsOf: configURL) else { return nil }
        return try? JSONDecoder().decode([CategoryConfig].self, from: data)
    }

    static func saveCategories(_ categories: [CategoryConfig]) {
        guard !categories.isEmpty else { return }
        ensureDirectories()
        guard let data = try? JSONEncoder().encode(categories) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    static func loadImage(for url: URL) -> UIImage? {
        ensureDirectories()
        let path = imageFileURL(for: url)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    static func saveImage(_ image: UIImage, for url: URL) {
        ensureDirectories()
        let path = imageFileURL(for: url)
        guard let data = image.pngData() else { return }
        try? data.write(to: path, options: .atomic)
    }

    private static func imageFileURL(for url: URL) -> URL {
        let safe = url.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return imagesDirectory.appendingPathComponent("\(safe.prefix(180)).png")
    }

    private static func ensureDirectories() {
        try? FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }
}
