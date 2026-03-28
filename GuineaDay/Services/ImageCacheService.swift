import UIKit

/// Simple in-memory image cache. Images persist for the app session so
/// Firebase Storage URLs are only downloaded once.
final class ImageCacheService {
    static let shared = ImageCacheService()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200        // max number of images
        cache.totalCostLimit = 100 * 1024 * 1024  // ~100 MB
    }

    func image(for url: String) -> UIImage? {
        cache.object(forKey: url as NSString)
    }

    func store(_ image: UIImage, for url: String) {
        let cost = Int(image.size.width * image.size.height * 4)  // rough byte estimate
        cache.setObject(image, forKey: url as NSString, cost: cost)
    }
}
