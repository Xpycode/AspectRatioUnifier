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
        /// ±1% tolerance for grouping images into the same bucket — §1.1 decision, user-overridable in Wave 6.
        static let bucketTolerance = 0.01
        /// ±0.2% snap threshold: if a bucket's mean ratio is this close to a named preset, use the preset label.
        static let namedPresetSnap = 0.002
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
