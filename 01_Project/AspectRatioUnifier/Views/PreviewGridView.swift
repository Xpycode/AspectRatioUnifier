import SwiftUI

struct PreviewGridView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let images: [ImageItem]
    let outputDirectory: URL
    let onConfirm: ([ImageItem]) -> Void

    var body: some View {
        if let targetSize = appState.targetSize {
            contentView(targetSize: targetSize)
        } else {
            placeholderView
        }
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Pick a ratio first")
                .font(.headline)
            Text("Tap a bar in the histogram to commit a target ratio, then export.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 700, minHeight: 500)
    }

    // MARK: - Content

    private func contentView(targetSize: CGSize) -> some View {
        let targetAspect = Double(targetSize.width / targetSize.height)
        let included = images.filter { !appState.isExcluded($0.id) }.count
        let upscaleIncluded = images.filter {
            !appState.isExcluded($0.id) &&
            ($0.originalSize.width < targetSize.width || $0.originalSize.height < targetSize.height)
        }.count
        let excluded = images.count - included

        return VStack(spacing: 0) {
            header(included: included, upscaleIncluded: upscaleIncluded, excluded: excluded)
            Divider()
            previewGrid(targetSize: targetSize, targetAspect: targetAspect)
            Divider()
            footer(
                targetSize: targetSize,
                included: included,
                upscaleIncluded: upscaleIncluded,
                excluded: excluded
            )
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    // MARK: - Header

    private func header(included: Int, upscaleIncluded: Int, excluded: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Review Batch Crop")
                    .font(.headline)
                Text(subtitleText(included: included, upscaleIncluded: upscaleIncluded, excluded: excluded))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }

    private func subtitleText(included: Int, upscaleIncluded: Int, excluded: Int) -> String {
        var parts: [String] = []
        if upscaleIncluded > 0 {
            parts.append("\(included) included (\(upscaleIncluded) upscale)")
        } else {
            parts.append("\(included) included")
        }
        if excluded > 0 {
            parts.append("\(excluded) excluded")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Preview Grid

    private func previewGrid(targetSize: CGSize, targetAspect: Double) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160, maximum: 220))],
                spacing: 16
            ) {
                ForEach(images) { item in
                    let isUpscale = item.originalSize.width < targetSize.width
                        || item.originalSize.height < targetSize.height
                    let isExcluded = appState.isExcluded(item.id)

                    VStack(spacing: 6) {
                        ZStack {
                            Image(nsImage: item.originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(6)

                            CropPreviewBadge(
                                sourceSize: item.originalSize,
                                targetAspect: targetAspect,
                                isUpscale: isUpscale,
                                isExcluded: isExcluded
                            )
                        }
                        .frame(height: 120)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.toggleExclusion(item.id)
                        }

                        Text(item.filename)
                            .font(.caption2)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 180)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isExcluded ? Color.red.opacity(0.05) : Color.clear)
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Footer

    private func footer(
        targetSize: CGSize,
        included: Int,
        upscaleIncluded: Int,
        excluded: Int
    ) -> some View {
        HStack(spacing: 12) {
            Button("Deselect upscales") {
                for item in images
                where item.originalSize.width < targetSize.width
                    || item.originalSize.height < targetSize.height
                {
                    appState.excludedImageIDs.insert(item.id)
                }
            }
            .disabled(upscaleIncluded == 0)

            Button("Reselect all") {
                appState.reselectAll()
            }
            .disabled(excluded == 0)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Output: \(outputDirectory.lastPathComponent)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Target: \(Int(targetSize.width)) × \(Int(targetSize.height))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            let fileLabel = included == 1 ? "File" : "Files"
            Button("Export \(included) \(fileLabel)") {
                onConfirm(images.filter { !appState.isExcluded($0.id) })
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(included == 0)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    PreviewGridView(
        images: [],
        outputDirectory: URL(fileURLWithPath: "/tmp")
    ) { _ in }
    .environment(AppState())
}
