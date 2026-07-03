import Foundation
import RealityKit

/// Process-wide cache for baked mesh textures (photo atlases, heatmap layers).
/// Bakes cost tens of milliseconds; a thumbnail and the full-screen viewer of the
/// same case should pay once.
enum FaceTextureCache {
    private static let cache: NSCache<NSString, TextureResource> = {
        let c = NSCache<NSString, TextureResource>()
        c.totalCostLimit = 64 * 1024 * 1024   // bytes, using width×height×4 as cost
        return c
    }()

    static func texture(forKey key: String) -> TextureResource? {
        cache.object(forKey: key as NSString)
    }

    static func store(_ texture: TextureResource, forKey key: String) {
        cache.setObject(texture, forKey: key as NSString,
                        cost: texture.width * texture.height * 4)
    }
}
