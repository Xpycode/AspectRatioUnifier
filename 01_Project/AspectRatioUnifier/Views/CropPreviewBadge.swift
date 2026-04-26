import SwiftUI

/// Visual overlay for a batch-preview thumbnail. Shows the centre-crop rectangle the
/// ratio-unify pipeline will keep, plus an upscale warning when the source pixel dims
/// are smaller than the target. Stateless — callers compute the inputs.
struct CropPreviewBadge: View {
    /// Source image pixel size.
    let sourceSize: CGSize
    /// Committed target aspect ratio (width / height). E.g. 1.5 for 3:2.
    let targetAspect: Double
    /// True when the source is smaller than target in either dimension.
    let isUpscale: Bool
    /// True when user has opted this item out of the batch.
    let isExcluded: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // Crop overlay and upscale badge dim together when excluded.
                ZStack(alignment: .topTrailing) {
                    cropOverlay(in: geo.size)
                    if isUpscale { upscaleBadge }
                }
                .opacity(isExcluded ? 0.4 : 1.0)

                // Red exclusion border renders at full opacity, outside the dim group.
                if isExcluded { excludedBorder }
            }
        }
        .allowsHitTesting(false) // Caller's tap gesture should win.
    }

    // MARK: - Crop overlay

    @ViewBuilder
    private func cropOverlay(in size: CGSize) -> some View {
        let sourceAspect = sourceSize.width / sourceSize.height

        if abs(sourceAspect - targetAspect) > 0.001 {
            // The image renders with .aspectRatio(.fit) inside `size`, so it occupies a
            // letterboxed sub-rectangle. Compute that first, then place the crop overlay
            // inside it — otherwise the dashed rectangle bleeds past the visible image edges
            // when source and container aspects diverge (e.g. 2:3 portrait in a wide cell).
            let imageRect = fitRect(sourceAspect: sourceAspect, in: size)
            let (rect, _) = cropRect(in: imageRect.size, sourceAspect: sourceAspect)

            Rectangle()
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                )
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                .frame(width: rect.width, height: rect.height)
                .offset(x: imageRect.minX + rect.minX, y: imageRect.minY + rect.minY)
        }
    }

    /// Mirrors SwiftUI's `.aspectRatio(_, contentMode: .fit)`: returns the centered
    /// sub-rectangle of `container` that the image occupies after letterboxing.
    private func fitRect(sourceAspect: Double, in container: CGSize) -> CGRect {
        let containerAspect = container.width / container.height
        if sourceAspect > containerAspect {
            // Source wider than container — fit width, letterbox top/bottom.
            let h = container.width / sourceAspect
            return CGRect(x: 0, y: (container.height - h) / 2, width: container.width, height: h)
        } else {
            // Source taller than container — fit height, letterbox left/right.
            let w = container.height * sourceAspect
            return CGRect(x: (container.width - w) / 2, y: 0, width: w, height: container.height)
        }
    }

    /// Returns the crop rectangle in display coordinates (origin at top-left of `size`).
    private func cropRect(in size: CGSize, sourceAspect: Double) -> (CGRect, Bool) {
        let isWider = sourceAspect > targetAspect

        let keptWidth: Double
        let keptHeight: Double
        let xOffset: Double
        let yOffset: Double

        if isWider {
            // Source wider than target → crop horizontally.
            keptWidth  = targetAspect / sourceAspect
            keptHeight = 1.0
            xOffset    = (1.0 - keptWidth) / 2.0
            yOffset    = 0.0
        } else {
            // Source taller than target → crop vertically.
            keptWidth  = 1.0
            keptHeight = sourceAspect / targetAspect
            xOffset    = 0.0
            yOffset    = (1.0 - keptHeight) / 2.0
        }

        let rect = CGRect(
            x:      xOffset    * size.width,
            y:      yOffset    * size.height,
            width:  keptWidth  * size.width,
            height: keptHeight * size.height
        )
        return (rect, isWider)
    }

    // MARK: - Upscale badge

    private var upscaleBadge: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.orange)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            .padding(4)
    }

    // MARK: - Excluded border

    private var excludedBorder: some View {
        RoundedRectangle(cornerRadius: 6)
            .strokeBorder(
                Color.red.opacity(0.8),
                style: StrokeStyle(lineWidth: 2, dash: [4, 3])
            )
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        // Case 1: Landscape source (3000×2000, aspect 1.5) → target 4:3 (1.333)
        // sourceAspect (1.5) > targetAspect (1.333) → horizontal crop → vertical dashed lines.
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.25))
            CropPreviewBadge(
                sourceSize:   CGSize(width: 3000, height: 2000),
                targetAspect: 4.0 / 3.0,
                isUpscale:    false,
                isExcluded:   false
            )
        }
        .frame(width: 160, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 6))

        // Case 2: Portrait source (2000×3000, aspect 0.667) → target 3:2 (1.5)
        // sourceAspect (0.667) < targetAspect (1.5) → vertical crop → horizontal dashed lines.
        ZStack {
            Rectangle()
                .fill(Color.green.opacity(0.25))
            CropPreviewBadge(
                sourceSize:   CGSize(width: 2000, height: 3000),
                targetAspect: 3.0 / 2.0,
                isUpscale:    false,
                isExcluded:   false
            )
        }
        .frame(width: 160, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 6))

        // Case 3: Matching aspect — no crop overlay — but isUpscale + isExcluded active.
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.25))
            CropPreviewBadge(
                sourceSize:   CGSize(width: 800, height: 600),
                targetAspect: 800.0 / 600.0,
                isUpscale:    true,
                isExcluded:   true
            )
        }
        .frame(width: 160, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    .padding(24)
    .background(Color.black)
}
