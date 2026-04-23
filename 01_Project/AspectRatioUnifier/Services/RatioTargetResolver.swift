import CoreGraphics
import Foundation

struct RatioTargetResolver {

    /// Translate a picked bucket into an export target. Returns the bucket's median size.
    /// The pipeline uses scale-to-fill + centre-crop (via ImageCropService.cropFill) when
    /// this value is stored in ExportSettings.ratioTarget.
    func resolve(bucket: AspectRatioBucket) -> CGSize {
        bucket.medianSize
    }

    /// Algorithm A "auto" fast-path — pick the highest-count bucket. Input is assumed
    /// sorted descending by count (as emitted by RatioAnalyzer). Nil if empty.
    func autoPick(from buckets: [AspectRatioBucket]) -> AspectRatioBucket? {
        buckets.first
    }
}
