import Foundation
import AppKit

@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: NSImage?

    private var currentURL: URL?

    init(url: URL?) {
        update(url: url)
    }

    func update(url: URL?) {
        guard currentURL != url else { return }
        currentURL = url

        image = nil

        Task {
            await load(from: url)
        }
    }

    private func load(from url: URL?) async {
        guard let url else { return }

        if let cachedData = await ImageCache.shared.data(for: url),
           let cachedImage = NSImage(data: cachedData) {
            self.image = cachedImage
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await ImageCache.shared.insert(data, for: url)
                self.image = nsImage
            }
        } catch {
            print("Image load failed:", error)
        }
    }
}

actor ImageCache {
    static let shared = ImageCache()
    private var cache: [URL: Data] = [:]

    func data(for url: URL) async -> Data? {
        cache[url]
    }

    func insert(_ data: Data, for url: URL) async {
        cache[url] = data
    }
}


