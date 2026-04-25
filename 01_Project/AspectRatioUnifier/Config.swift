import Foundation

/// Centralized configuration constants for the app
enum Config {
    // MARK: - History / Undo
    enum History {
        /// Maximum number of undo steps to keep
        static let maxUndoSteps = 50
    }

    // MARK: - Memory Management
    enum Memory {
        /// Number of images that triggers a memory warning
        static let imageCountWarningThreshold = 50
        /// Number of images that triggers a critical memory warning
        static let imageCountCriticalThreshold = 100
    }

    // MARK: - Blur Tool
    enum Blur {
        /// Minimum size for a blur region (as fraction of image dimension)
        static let minimumRegionSize = 0.02
    }

    // MARK: - Thumbnail Cache
    enum Cache {
        /// Maximum number of thumbnails to keep in memory
        static let thumbnailCountLimit = 100
        /// Maximum total memory for cached thumbnails (50MB)
        static let thumbnailSizeLimit = 50 * 1024 * 1024
    }

    // MARK: - Snap Points
    enum Snap {
        /// Default threshold in pixels for edge snapping
        static let defaultThreshold = 15
    }

    // MARK: - Presets
    enum Presets {
        /// Maximum number of recent presets to track
        static let recentLimit = 5
    }

    // MARK: - Ratio Analysis

    enum Ratio {
        /// ±1% single-link threshold: max gap between two consecutive sorted ratios for them to chain
        /// into the same bucket. §1.1 decision, user-overridable in Wave 6.
        static let bucketTolerance = 0.01
        /// ±5% complete-link diameter cap: max total span any single bucket may grow to. Stops the
        /// chain from running across naturally-distinct clusters (4:3 → 3:2 → 16:10). Picked to cover
        /// the ~4% scanner-noise width of a 35mm-scan 3:2 cluster.
        static let bucketMaxSpan = 0.05
        /// ±2.5% snap threshold: if a bucket's mean ratio is this close to a named preset, use the
        /// preset label. Sized to roughly half the bucketMaxSpan so a bucket's center can drift
        /// within its diameter and still snap. Safe because the named-preset list is sparse — the
        /// gap from 4:3 (1.333) to 3:2 (1.5) is 12.5%, so a 2.5% snap never collides.
        static let namedPresetSnap = 0.025
        /// Named aspect-ratio presets used for labelling and snap matching.
        static let namedPresets: [(ratio: Double, label: String)] = [
            (1.0,           "1:1"),
            (0.8,           "4:5"),
            (1.25,          "5:4"),
            (4.0 / 3.0,     "4:3"),
            (3.0 / 2.0,     "3:2"),
            (16.0 / 9.0,    "16:9"),
            (16.0 / 10.0,   "16:10"),
            (9.0 / 16.0,    "9:16"),
            (2.0 / 3.0,     "2:3"),
            (3.0 / 4.0,     "3:4"),
        ]
        /// Maximum concurrent metadata-probe tasks — bounded by active processor count, minimum 2.
        static var concurrency: Int { max(2, ProcessInfo.processInfo.activeProcessorCount) }
    }
}
