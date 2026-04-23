import Foundation
import AppKit

/// v1 stub — folder-watch mode is out of scope (see docs/IMPLEMENTATION_PLAN.md §6).
/// UI references (`FolderWatcher.shared.isWatching`) still work but the watcher is inert.
@MainActor
@Observable
final class FolderWatcher {
    static let shared = FolderWatcher()

    var isWatching = false
    var watchedFolder: URL?
    var outputFolder: URL?
    var exportSettings = ExportSettings()

    var processedCount = 0
    var lastProcessedFile: String?
    var errorMessage: String?

    private init() {}

    func startWatching(folder: URL, output: URL) {}
    func stopWatching() {}
}
