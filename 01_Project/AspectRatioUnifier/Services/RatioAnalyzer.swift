import CoreGraphics
import Foundation
import ImageIO

// MARK: - RatioAnalyzer

/// Stateless transformer: reads pixel dimensions from image metadata and groups
/// images into aspect-ratio buckets. No image decode — metadata only (~10ms/file on SSD).
struct RatioAnalyzer {

    // MARK: - Public API

    func analyze(urls: [URL]) async -> [AspectRatioBucket] {
        // URL-only path: generate synthetic IDs since no ImageItem.id is available.
        let urlEntries = urls.map { (id: UUID(), url: $0) }
        let probeResults = await probeAll(entries: urlEntries)
        return bucket(probeResults)
    }

    /// Convenience overload — preserves each ImageItem.id as the BucketItem.imageID.
    func analyze(items: [ImageItem]) async -> [AspectRatioBucket] {
        let entries = items.map { (id: $0.id, url: $0.url) }
        let probeResults = await probeAll(entries: entries)
        return bucket(probeResults)
    }

    // MARK: - Private types

    private struct ProbeResult {
        let imageID: UUID
        let url: URL
        let pixelSize: CGSize
        let ratio: Double
    }

    // MARK: - Metadata probing

    private func probeAll(entries: [(id: UUID, url: URL)]) async -> [ProbeResult] {
        let concurrency = Config.Ratio.concurrency
        var results: [ProbeResult] = []

        await withTaskGroup(of: ProbeResult?.self) { group in
            var inFlight = 0
            var iterator = entries.makeIterator()

            // Seed initial batch up to concurrency cap
            while inFlight < concurrency, let entry = iterator.next() {
                group.addTask { await Self.probe(id: entry.id, url: entry.url) }
                inFlight += 1
            }

            // Drain completed tasks, feeding new ones to stay at capacity
            for await result in group {
                if let r = result {
                    results.append(r)
                }
                inFlight -= 1
                if let entry = iterator.next() {
                    group.addTask { await Self.probe(id: entry.id, url: entry.url) }
                    inFlight += 1
                }
            }
        }

        return results
    }

    private static func probe(id: UUID, url: URL) async -> ProbeResult? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else {
            AspectRatioUnifierLogger.storage.warning("RatioAnalyzer: cannot create image source for \(url.lastPathComponent, privacy: .public)")
            return nil
        }

        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, options) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int,
              w > 0, h > 0 else {
            AspectRatioUnifierLogger.storage.warning("RatioAnalyzer: missing pixel dimensions for \(url.lastPathComponent, privacy: .public)")
            return nil
        }

        let size = CGSize(width: w, height: h)
        let ratio = Double(w) / Double(h)
        return ProbeResult(imageID: id, url: url, pixelSize: size, ratio: ratio)
    }

    // MARK: - Bucketing

    private func bucket(_ probes: [ProbeResult]) -> [AspectRatioBucket] {
        guard !probes.isEmpty else { return [] }

        // Sort ascending by ratio so the greedy pass is O(n log n) total
        let sorted = probes.sorted { $0.ratio < $1.ratio }

        // Greedy single-pass grouping: extend the current bucket while ratio
        // is within ±bucketTolerance of the first member; open a new bucket otherwise.
        var groups: [[ProbeResult]] = []
        var current: [ProbeResult] = []

        for probe in sorted {
            if let first = current.first {
                let tol = Config.Ratio.bucketTolerance
                if abs(probe.ratio - first.ratio) / max(probe.ratio, first.ratio) <= tol {
                    current.append(probe)
                    continue
                }
            }
            if !current.isEmpty { groups.append(current) }
            current = [probe]
        }
        if !current.isEmpty { groups.append(current) }

        // Build AspectRatioBucket for each group
        let buckets = groups.map { group -> AspectRatioBucket in
            let items = group.map { BucketItem(imageID: $0.imageID, pixelSize: $0.pixelSize, ratio: $0.ratio) }
            // Mean ratio for preset snapping
            let meanRatio = group.map(\.ratio).reduce(0, +) / Double(group.count)
            let (label, isNamed) = resolveLabel(for: meanRatio)
            let median = medianSize(of: group.map(\.pixelSize))

            return AspectRatioBucket(
                id: UUID(),
                ratio: meanRatio,
                label: label,
                items: items,
                medianSize: median,
                isNamedPreset: isNamed
            )
        }

        // Stable sort descending by count (Swift sort is stable since 5.0)
        return buckets.sorted { $0.items.count > $1.items.count }
    }

    // MARK: - Label resolution

    private func resolveLabel(for ratio: Double) -> (label: String, isNamed: Bool) {
        let snap = Config.Ratio.namedPresetSnap
        for preset in Config.Ratio.namedPresets {
            if abs(ratio - preset.ratio) / max(ratio, preset.ratio) <= snap {
                return (preset.label, true)
            }
        }
        // No match — format as "X.XX:1"
        return (String(format: "%.2f:1", ratio), false)
    }

    // MARK: - Median size

    private func medianSize(of sizes: [CGSize]) -> CGSize {
        let widths  = sizes.map(\.width).sorted()
        let heights = sizes.map(\.height).sorted()
        return CGSize(width: median(of: widths), height: median(of: heights))
    }

    private func median(of values: [CGFloat]) -> CGFloat {
        let n = values.count
        guard n > 0 else { return 0 }
        if n % 2 == 1 {
            return values[n / 2]
        } else {
            return (values[n / 2 - 1] + values[n / 2]) / 2
        }
    }
}
