import UIKit

/// Two-layer image cache: memory (NSCache) + disk (Caches directory).
/// Images downloaded from Firebase Storage are saved to disk and survive
/// app relaunches — no more spinners after the very first download.
final class ImageCacheService {
    static let shared = ImageCacheService()

    private let memory = NSCache<NSString, UIImage>()
    private let cacheDir: URL

    private init() {
        memory.countLimit = 200
        memory.totalCostLimit = 100 * 1024 * 1024  // 100 MB

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDir = caches.appendingPathComponent("firebase_photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Read (memory → disk → nil)

    func image(for urlStr: String) -> UIImage? {
        // 1. Memory hit — instant
        if let cached = memory.object(forKey: urlStr as NSString) { return cached }

        // 2. Disk hit — fast (~5ms), warm memory cache for next call
        let file = cacheDir.appendingPathComponent(filename(for: urlStr))
        if let data = try? Data(contentsOf: file), let img = UIImage(data: data) {
            memory.setObject(img, forKey: urlStr as NSString)
            return img
        }
        return nil
    }

    // MARK: - Write (memory + disk)

    func store(_ image: UIImage, for urlStr: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        memory.setObject(image, forKey: urlStr as NSString, cost: cost)

        // Persist to disk so it survives app relaunches
        let file = cacheDir.appendingPathComponent(filename(for: urlStr))
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: file, options: .atomic)
        }
    }

    // MARK: - Stable filename from URL (FNV-1a hash)

    private func filename(for urlStr: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in urlStr.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return "img_\(hash).jpg"
    }
}
