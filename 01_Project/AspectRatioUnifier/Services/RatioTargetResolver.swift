import CoreGraphics
import Foundation

struct RatioTargetResolver {

    /// Translate a picked bucket into an export target. Target is the bucket's median size.
    /// Returned `scaleMode` is the closest existing `ResizeMode` — Wave 5 needs to replace or
    /// supplement this with a scale-to-fill-and-centre-crop path, because `.exactSize` with
    /// `maintainAspectRatio = true` letterboxes (scale-to-fit) instead of filling + cropping
    /// the overhang. The plan §3.5 specifies the latter. This is the only spec deviation in
    /// Wave 4 — kept benign because the "Pick as target" button is cosmetic until Wave 5.
    func resolve(bucket: AspectRatioBucket) -> (targetSize: CGSize, scaleMode: ResizeMode) {
        (bucket.medianSize, .exactSize)
    }

    /// Algorithm A "auto" fast-path — pick the highest-count bucket. Input is assumed
    /// sorted descending by count (as emitted by RatioAnalyzer). Nil if empty.
    func autoPick(from buckets: [AspectRatioBucket]) -> AspectRatioBucket? {
        buckets.first
    }
}
