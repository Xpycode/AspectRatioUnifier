import AppKit
import CoreGraphics
import CoreImage
import SwiftUI
import UniformTypeIdentifiers

enum ImageCropError: LocalizedError {
    case failedToGetCGImage
    case invalidCropRegion
    case failedToCreateDestination
    case failedToWriteImage
    case wouldOverwriteOriginal(String)
    case filenameCollision(String)
    case failedToCreateContext
    case failedToResize
    case invalidTargetSize

    var errorDescription: String? {
        switch self {
        case .failedToGetCGImage:       return "Failed to convert image to bitmap format"
        case .invalidCropRegion:        return "Crop region is larger than the image"
        case .failedToCreateDestination:return "Failed to create output file"
        case .failedToWriteImage:       return "Failed to write output image"
        case .wouldOverwriteOriginal(let filename):
            return "Would overwrite original file: \(filename). Please use a different suffix."
        case .filenameCollision(let filename):
            return "Filename collision detected: \(filename). Multiple images would export to the same file."
        case .failedToCreateContext:    return "Failed to create graphics context for image processing"
        case .failedToResize:           return "Failed to resize image"
        case .invalidTargetSize:        return "Invalid target size for resize operation"
        }
    }
}

/// Image processing pipeline for AspectRatioUnifier.
///
/// v1 supports resize-only. Wave 5 extends this with the ratio-driven scale-to-fill
/// + center-crop path that conforms outliers to the picked target bucket.
struct ImageCropService {

    // MARK: - Size calculation

    static func calculateResizedSize(from originalSize: CGSize, with settings: ResizeSettings) -> CGSize? {
        guard settings.isEnabled else { return nil }

        switch settings.mode {
        case .none:
            return nil
        case .exactSize:
            if settings.maintainAspectRatio {
                let scale = min(CGFloat(settings.width) / originalSize.width,
                                CGFloat(settings.height) / originalSize.height)
                return CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
            } else {
                return CGSize(width: settings.width, height: settings.height)
            }
        case .maxWidth:
            guard originalSize.width > CGFloat(settings.width) else { return nil }
            let scale = CGFloat(settings.width) / originalSize.width
            return CGSize(width: CGFloat(settings.width), height: originalSize.height * scale)
        case .maxHeight:
            guard originalSize.height > CGFloat(settings.height) else { return nil }
            let scale = CGFloat(settings.height) / originalSize.height
            return CGSize(width: originalSize.width * scale, height: CGFloat(settings.height))
        case .percentage:
            let scale = settings.percentage / 100.0
            return CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        }
    }

    // MARK: - Resize

    /// Thread-safe resize using pure CGContext. NSGraphicsContext is NOT thread-safe.
    static func resize(_ image: NSImage, to targetSize: CGSize) throws -> NSImage {
        let targetWidth = Int(targetSize.width)
        let targetHeight = Int(targetSize.height)
        guard targetWidth > 0 && targetHeight > 0 else {
            throw ImageCropError.invalidTargetSize
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageCropError.failedToGetCGImage
        }

        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ImageCropError.failedToCreateContext
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))

        guard let resizedCGImage = context.makeImage() else {
            throw ImageCropError.failedToResize
        }
        return NSImage(cgImage: resizedCGImage, size: targetSize)
    }

    // MARK: - Normalized CGImage (applies EXIF orientation)

    /// Returns a CGImage with any EXIF/NSImage orientation baked in, so pixel coords match what the user sees.
    private static func createNormalizedCGImage(from image: NSImage) -> CGImage? {
        guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let pixelSize = CGSize(width: source.width, height: source.height)
        let colorSpace = source.colorSpace ?? CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: nil,
            width: Int(pixelSize.width),
            height: Int(pixelSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.draw(source, in: CGRect(origin: .zero, size: pixelSize))
        return ctx.makeImage()
    }

    // MARK: - Save / encode

    static func save(_ image: NSImage, to url: URL, format: UTType = .png, quality: Double = 0.9) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageCropError.failedToGetCGImage
        }

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            format.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageCropError.failedToCreateDestination
        }

        var properties: [CFString: Any] = [:]
        if format == .jpeg || format == .heic {
            properties[kCGImageDestinationLossyCompressionQuality] = quality
        }

        let cfProperties = properties.isEmpty ? nil : properties as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, cfProperties)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageCropError.failedToWriteImage
        }
    }

    static func encode(_ image: NSImage, format: ExportFormat, quality: Double = 0.9) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
        case .heic, .webp:
            let utType = format == .heic ? UTType.heic : UTType.webP
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data as CFMutableData,
                utType.identifier as CFString,
                1,
                nil
            ) else { return nil }
            CGImageDestinationAddImage(destination, cgImage, [
                kCGImageDestinationLossyCompressionQuality: quality
            ] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { return nil }
            return data as Data
        case .tiff:
            return bitmapRep.representation(using: .tiff, properties: [:])
        }
    }

    // MARK: - Batch pipeline

    /// Processes multiple images in parallel with resize + encode + save.
    /// Progress is a main-actor closure reporting 0.0–1.0.
    static func batchCrop(
        items: [ImageItem],
        exportSettings: ExportSettings,
        progress: @escaping @MainActor (Double) -> Void
    ) async throws -> [URL] {
        let total = Double(items.count)

        if !exportSettings.outputDirectory.isOverwriteMode {
            for item in items {
                if exportSettings.wouldOverwriteOriginal(for: item.url) {
                    throw ImageCropError.wouldOverwriteOriginal(item.filename)
                }
            }
        }

        if let collidingFilename = exportSettings.findBatchCollision(items: items) {
            throw ImageCropError.filenameCollision(collidingFilename)
        }

        return try await withThrowingTaskGroup(of: (Int, URL).self) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let url = try processSingleImage(
                        item: item,
                        index: index,
                        exportSettings: exportSettings
                    )
                    return (index, url)
                }
            }

            var results: [(Int, URL)] = []
            var completed = 0.0
            for try await result in group {
                results.append(result)
                completed += 1
                let fraction = completed / total
                await progress(fraction)
            }

            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    /// Single-image resize + encode + save.
    static func processSingleImage(
        item: ImageItem,
        index: Int,
        exportSettings: ExportSettings
    ) throws -> URL {
        var image = item.originalImage

        if let targetSize = calculateResizedSize(from: item.originalSize, with: exportSettings.resizeSettings) {
            image = try resize(image, to: targetSize)
        }

        let outputURL = exportSettings.outputURL(for: item.url, index: index)
        let utType: UTType
        switch exportSettings.format {
        case .png:  utType = .png
        case .jpeg: utType = .jpeg
        case .heic: utType = .heic
        case .webp: utType = .webP
        case .tiff: utType = .tiff
        }

        if case .custom(let dir) = exportSettings.outputDirectory {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        try save(image, to: outputURL, format: utType, quality: exportSettings.quality)
        return outputURL
    }
}
