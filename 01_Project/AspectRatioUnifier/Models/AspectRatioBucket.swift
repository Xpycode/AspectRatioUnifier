import CoreGraphics
import Foundation

// MARK: - AspectRatioBucket

/// A group of images that share an aspect ratio within ±Config.Ratio.bucketTolerance.
struct AspectRatioBucket: Identifiable, Hashable {
    let id: UUID
    let ratio: Double           // e.g. 1.5 for 3:2
    let label: String           // "3:2", "4:3", or "1.67:1" when no named match
    let items: [BucketItem]
    let medianSize: CGSize
    let isNamedPreset: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AspectRatioBucket, rhs: AspectRatioBucket) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - BucketItem

/// A single image's membership record within an AspectRatioBucket.
struct BucketItem: Hashable {
    let imageID: UUID           // ImageItem.id
    let pixelSize: CGSize
    let ratio: Double
    var isExcluded: Bool = false

    /// Returns true if the source must be upscaled in either dimension to meet the target.
    func requiresUpscale(target: CGSize) -> Bool {
        pixelSize.width < target.width || pixelSize.height < target.height
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(imageID)
        hasher.combine(pixelSize.width)
        hasher.combine(pixelSize.height)
        hasher.combine(ratio)
        hasher.combine(isExcluded)
    }

    static func == (lhs: BucketItem, rhs: BucketItem) -> Bool {
        lhs.imageID == rhs.imageID &&
        lhs.pixelSize == rhs.pixelSize &&
        lhs.ratio == rhs.ratio &&
        lhs.isExcluded == rhs.isExcluded
    }
}
