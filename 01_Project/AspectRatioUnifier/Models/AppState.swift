import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

/// Zoom modes for the image preview
enum ZoomMode: String, CaseIterable, Identifiable {
    case actualSize = "100%"
    case fit = "Fit"
    case fitWidth = "Fit Width"
    case fitHeight = "Fit Height"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .actualSize: return "1.circle"
        case .fit: return "arrow.up.left.and.arrow.down.right"
        case .fitWidth: return "arrow.left.and.right"
        case .fitHeight: return "arrow.up.and.down"
        }
    }

    var shortcut: String {
        switch self {
        case .actualSize: return "⌘1"
        case .fit: return "⌘2"
        case .fitWidth: return "⌘3"
        case .fitHeight: return "⌘4"
        }
    }
}

/// Main application state.
/// AspectRatioUnifier composes an ImageManager and an ExportSettings bag; the crop/blur/watermark/snap
/// machinery inherited from CropBatch has been stripped. Future waves add RatioAnalyzer + bucket state here.
@MainActor
@Observable
final class AppState {

    // MARK: - Composed Managers

    let imageManager = ImageManager()

    // MARK: - Export Settings

    var exportSettings = ExportSettings()
    var selectedPresetID: String? = "png_lossless"
    var showOutputDirectoryPicker = false
    var isProcessing = false
    var processingProgress: Double = 0

    private var currentExportTask: Task<[URL], Error>?

    // MARK: - View State

    var zoomMode: ZoomMode = .fit
    var showBeforeAfter = false

    // MARK: - Initialization

    init() {}

    // MARK: - Image Manager delegations (backward compat with kept views)

    var images: [ImageItem] {
        get { imageManager.images }
        set { imageManager.images = newValue }
    }

    var selectedImageIDs: Set<UUID> {
        get { imageManager.selectedImageIDs }
        set { imageManager.selectedImageIDs = newValue }
    }

    var activeImageID: UUID? {
        get { imageManager.activeImageID }
        set { imageManager.activeImageID = newValue }
    }

    var loopNavigation: Bool {
        get { imageManager.loopNavigation }
        set { imageManager.loopNavigation = newValue }
    }

    var selectedImages: [ImageItem] { imageManager.selectedImages }
    var activeImage: ImageItem? { imageManager.activeImage }
    var majorityResolution: CGSize? { imageManager.majorityResolution }
    var mismatchedImages: [ImageItem] { imageManager.mismatchedImages }
    var hasResolutionMismatch: Bool { imageManager.hasResolutionMismatch }
    var memoryWarningLevel: ImageManager.MemoryWarningLevel { imageManager.memoryWarningLevel }
    var shouldShowMemoryWarning: Bool { imageManager.shouldShowMemoryWarning }
    var memoryWarningMessage: String? { imageManager.memoryWarningMessage }

    // MARK: - Image methods

    func addImages(from urls: [URL]) {
        let result = imageManager.addImages(from: urls)
        if let format = result.detectedFormat {
            exportSettings.format = format
            selectedPresetID = nil
        }
    }

    @MainActor
    func showImportPanel() {
        imageManager.showImportPanel { [weak self] detectedFormat in
            guard let self else { return }
            if let format = detectedFormat {
                self.exportSettings.format = format
                self.selectedPresetID = nil
            }
        }
    }

    func removeImages(ids: Set<UUID>) {
        imageManager.removeImages(ids: ids)
    }

    func clearAll() {
        imageManager.clearAll()
    }

    func setActiveImage(_ id: UUID) {
        imageManager.setActiveImage(id)
    }

    func moveImage(from source: IndexSet, to destination: Int) {
        imageManager.moveImage(from: source, to: destination)
    }

    func reorderImage(id: UUID, toIndex: Int) {
        imageManager.reorderImage(id: id, toIndex: toIndex)
    }

    func selectNextImage() {
        imageManager.selectNextImage()
    }

    func selectPreviousImage() {
        imageManager.selectPreviousImage()
    }

    // MARK: - Export preset

    var selectedPreset: ExportPreset? {
        ExportPreset.presets.first { $0.id == selectedPresetID }
    }

    func applyPreset(_ preset: ExportPreset) {
        selectedPresetID = preset.id
        exportSettings = preset.settings
    }

    func markCustomSettings() {
        selectedPresetID = nil
    }

    // MARK: - Export capability
    //
    // v1 (pre-ratio-analysis) can export when a resize is configured or a
    // rename pattern is chosen. Wave 4+ adds the bucket-driven target path.

    var canExport: Bool {
        !images.isEmpty &&
        !isProcessing &&
        (exportSettings.resizeSettings.isEnabled ||
         exportSettings.renameSettings.mode == .pattern ||
         !exportSettings.preserveOriginalFormat)
    }

    // MARK: - Export operations
    //
    // Simplified from CropBatch: no cropSettings / transform / blurRegions.
    // The ratio-driven target path lands in Wave 5.

    @MainActor
    func processAndExport(images imagesToExport: [ImageItem]? = nil, to outputDirectory: URL) async throws -> [URL] {
        currentExportTask?.cancel()

        let items = imagesToExport ?? (selectedImageIDs.isEmpty ? self.images : selectedImages)
        var captured = exportSettings
        captured.outputDirectory = .custom(outputDirectory)

        isProcessing = true
        processingProgress = 0

        let task = Task<[URL], Error> { [weak self] in
            defer {
                Task { @MainActor in
                    self?.isProcessing = false
                    self?.currentExportTask = nil
                }
            }

            try Task.checkCancellation()

            return try await ImageCropService.batchCrop(
                items: items,
                exportSettings: captured
            ) { progress in
                Task { @MainActor in
                    self?.processingProgress = progress
                }
            }
        }

        currentExportTask = task
        return try await task.value
    }

    @MainActor
    func processAndExportInPlace(images imagesToExport: [ImageItem]) async throws -> [URL] {
        currentExportTask?.cancel()

        var captured = exportSettings
        captured.outputDirectory = .overwriteOriginal

        isProcessing = true
        processingProgress = 0

        let task = Task<[URL], Error> { [weak self] in
            defer {
                Task { @MainActor in
                    self?.isProcessing = false
                    self?.currentExportTask = nil
                }
            }

            try Task.checkCancellation()

            return try await ImageCropService.batchCrop(
                items: imagesToExport,
                exportSettings: captured
            ) { progress in
                Task { @MainActor in
                    self?.processingProgress = progress
                }
            }
        }

        currentExportTask = task
        return try await task.value
    }

    func sendExportNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Export Complete"
        content.body = "\(count) image\(count == 1 ? "" : "s") exported successfully"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - ImageItem

struct ImageItem: Identifiable {
    let id = UUID()
    let url: URL
    let originalImage: NSImage
    let fileSize: Int64
    var isProcessed = false

    init(url: URL, originalImage: NSImage) {
        self.url = url
        self.originalImage = originalImage
        self.fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }

    var filename: String {
        url.lastPathComponent
    }

    // NSImage.size returns POINTS; CGImage.width/height returns PIXELS. On Retina displays
    // a screenshot's NSImage.size (points) != CGImage size (pixels). Use pixels throughout.
    var originalSize: CGSize {
        guard let cgImage = originalImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return originalImage.size
        }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }

    var fileExtension: String {
        url.pathExtension.lowercased()
    }

    var isLossyFormat: Bool {
        ["jpg", "jpeg", "heic"].contains(fileExtension)
    }
}
