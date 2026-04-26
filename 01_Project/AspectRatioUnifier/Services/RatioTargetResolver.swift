import CoreGraphics
import Foundation

/// User-selectable strategy for sizing the export target once a ratio has been picked.
/// Min and Max are global properties of the included image set; Median is local to the
/// picked bucket. The asymmetry is intentional — Median preserves "what the dominant
/// cluster's resolution actually was", while Min/Max answer global questions like
/// "what's the largest size that requires no upscaling?".
enum TargetSizeStrategy: String, CaseIterable, Identifiable {
    case min, median, max

    var id: String { rawValue }

    var label: String {
        switch self {
        case .min:    "Min"
        case .median: "Median"
        case .max:    "Max"
        }
    }

    var help: String {
        switch self {
        case .min:    "Largest size that doesn't require upscaling any image"
        case .median: "Median dimensions of the dominant bucket"
        case .max:    "Largest dimensions in the set — most images will be upscaled"
        }
    }
}

struct RatioTargetResolver {

    /// Translate a picked bucket into an export target. The strategy decides how
    /// dimensions are derived once the ratio (from `bucket`) is fixed.
    /// - Parameters:
    ///   - bucket: source of the target *ratio*; for `.median`, also source of dimensions.
    ///   - sources: full set of images that will be exported, used by `.min`/`.max`.
    func resolve(
        bucket: AspectRatioBucket,
        sources: [CGSize],
        strategy: TargetSizeStrategy
    ) -> CGSize {
        switch strategy {
        case .median:
            return bucket.medianSize
        case .min:
            return reduceInscribed(sources: sources, ratio: bucket.ratio, pick: Swift.min)
        case .max:
            return reduceInscribed(sources: sources, ratio: bucket.ratio, pick: Swift.max)
        }
    }

    /// Algorithm A "auto" fast-path — pick the highest-count bucket. Input is assumed
    /// sorted descending by count (as emitted by RatioAnalyzer). Nil if empty.
    func autoPick(from buckets: [AspectRatioBucket]) -> AspectRatioBucket? {
        buckets.first
    }

    // MARK: - Inscribed-rectangle math

    /// Largest rectangle of the given aspect ratio that fits inside `source` without
    /// upscaling. Equivalent to the post-crop rectangle when scale-to-fit (not fill).
    /// If source is wider than the target ratio, height is binding; otherwise width is.
    private func inscribed(in source: CGSize, ratio: Double) -> CGSize {
        let sourceRatio = source.width / source.height
        if sourceRatio >= ratio {
            // Source is wider — keep height, derive width from ratio.
            return CGSize(width: source.height * ratio, height: source.height)
        } else {
            // Source is taller — keep width, derive height from ratio.
            return CGSize(width: source.width, height: source.width / ratio)
        }
    }

    /// Reduce inscribed rectangles across all sources via min or max on the height axis.
    /// Width is then derived from the chosen height to preserve the target ratio exactly.
    /// (Reducing on width and deriving height would yield the same rectangle; we pick
    /// height arbitrarily.)
    private func reduceInscribed(
        sources: [CGSize],
        ratio: Double,
        pick: (CGFloat, CGFloat) -> CGFloat
    ) -> CGSize {
        guard let first = sources.first else { return .zero }
        var heightPick = inscribed(in: first, ratio: ratio).height
        for source in sources.dropFirst() {
            heightPick = pick(heightPick, inscribed(in: source, ratio: ratio).height)
        }
        return CGSize(width: heightPick * ratio, height: heightPick)
    }
}
