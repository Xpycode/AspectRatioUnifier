import SwiftUI

struct ImageGridView: View {
    @Environment(AppState.self) private var appState

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 250), spacing: 16)
    ]

    /// Filter by ratioFilter (empty = all), then sort by aspect ratio ascending.
    private var visibleImages: [ImageItem] {
        let allowed = appState.filteredImageIDs
        return appState.images
            .filter { allowed.contains($0.id) }
            .sorted { a, b in
                let ra = a.originalSize.width / a.originalSize.height
                let rb = b.originalSize.width / b.originalSize.height
                if ra == rb { return a.id.uuidString < b.id.uuidString }
                return ra < rb
            }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(visibleImages) { item in
                    ImageThumbnailView(item: item)
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    appState.selectedImageIDs = Set(appState.images.map(\.id))
                } label: {
                    Label("Select All", systemImage: "checkmark.circle")
                }
                .disabled(appState.images.isEmpty)

                Button {
                    appState.selectedImageIDs.removeAll()
                } label: {
                    Label("Deselect All", systemImage: "circle")
                }
                .disabled(appState.selectedImageIDs.isEmpty)

                Divider()

                Button {
                    appState.showImportPanel()
                } label: {
                    Label("Add Images", systemImage: "plus")
                }

                Button(role: .destructive) {
                    if appState.selectedImageIDs.isEmpty {
                        appState.clearAll()
                    } else {
                        appState.removeImages(ids: appState.selectedImageIDs)
                    }
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(appState.images.isEmpty)
            }
        }
    }
}

struct ImageThumbnailView: View {
    let item: ImageItem
    @Environment(AppState.self) private var appState
    @State private var isHovering = false

    private var isSelected: Bool {
        appState.selectedImageIDs.contains(item.id)
    }

    /// Prefer the bucket label (handles named-preset snapping like "3:2" vs
    /// "1.15:1"). Fall back to a computed ratio if no bucket includes this
    /// image (shouldn't happen normally, but keeps the label live during the
    /// analysis window).
    private var ratioLabel: String {
        for bucket in appState.buckets {
            if bucket.items.contains(where: { $0.imageID == item.id }) {
                return bucket.label
            }
        }
        let r = item.originalSize.width / item.originalSize.height
        return String(format: "%.2f:1", r)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: item.originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .bottomTrailing) {
                        Text(ratioLabel)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(6)
                    }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .background(Circle().fill(.blue).padding(-2))
                        .padding(8)
                }
            }

            VStack(spacing: 2) {
                Text(item.filename)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("\(Int(item.originalSize.width)) × \(Int(item.originalSize.height))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(isHovering ? 0.1 : 0.05), radius: isHovering ? 8 : 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            if isSelected {
                appState.selectedImageIDs.remove(item.id)
            } else {
                appState.selectedImageIDs.insert(item.id)
            }
        }
    }
}

#Preview {
    let state = AppState()
    return ImageGridView()
        .environment(state)
        .frame(width: 600, height: 400)
}
