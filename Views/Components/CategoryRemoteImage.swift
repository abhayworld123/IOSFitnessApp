import SwiftUI
import UIKit

/// Loads remote category artwork via URLSession (more reliable than AsyncImage for R2 URLs).
struct CategoryRemoteImage<Placeholder: View>: View {
    let url: URL
    /// `.fit` shows the full admin-uploaded card artwork; `.fill` crops to the frame.
    var contentMode: ContentMode = .fit
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: url.absoluteString) {
            await load()
        }
    }

    private func load() async {
        if let cached = CategoryImageCache.shared.image(for: url) {
            uiImage = cached
            return
        }

        do {
            let request = ExerciseAPIHTTPClient.preparedRequest(url: url)
            let (data, response) = try await ExerciseAPIHTTPClient.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let image = UIImage(data: data) else {
                return
            }
            CategoryImageCache.shared.store(image, for: url)
            uiImage = image
        } catch {
            // Keep placeholder; disk/memory cache may populate on next appear after a successful fetch.
        }
    }
}

/// Memory + disk cache for category images.
final class CategoryImageCache {
    static let shared = CategoryImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 48
    }

    func image(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        if let mem = cache.object(forKey: key) { return mem }
        if let disk = CategoryDiskCache.loadImage(for: url) {
            cache.setObject(disk, forKey: key)
            return disk
        }
        return nil
    }

    func store(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        cache.setObject(image, forKey: key)
        CategoryDiskCache.saveImage(image, for: url)
    }

    func prefetch(urls: [URL]) {
        Task {
            for url in urls {
                if image(for: url) != nil { continue }
                do {
                    let request = ExerciseAPIHTTPClient.preparedRequest(url: url)
                    let (data, response) = try await ExerciseAPIHTTPClient.data(for: request)
                    guard let http = response as? HTTPURLResponse,
                          (200...299).contains(http.statusCode),
                          let image = UIImage(data: data) else { continue }
                    store(image, for: url)
                } catch {
                    continue
                }
            }
        }
    }
}

/// Chip-sized remote icon (Create Workout / Video Library).
struct CategoryRemoteIcon: View {
    let url: URL
    let fallbackSystemName: String
    var size: CGFloat = 18
    var tint: Color = .primary

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(tint)
            } else {
                Image(systemName: fallbackSystemName)
                    .font(.system(size: size, weight: .medium))
                    .foregroundColor(tint)
            }
        }
        .task(id: url.absoluteString) {
            if let cached = CategoryImageCache.shared.image(for: url) {
                uiImage = cached
                return
            }
            do {
                let request = ExerciseAPIHTTPClient.preparedRequest(url: url)
                let (data, response) = try await ExerciseAPIHTTPClient.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      let image = UIImage(data: data) else { return }
                CategoryImageCache.shared.store(image, for: url)
                uiImage = image
            } catch {}
        }
    }
}
