import SwiftUI
import UniformTypeIdentifiers

// MARK: - Content View

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showShortcutsPopover = false
    @State private var showClearAllConfirmation = false

    var body: some View {
        HStack(spacing: 0) {
            if appState.images.isEmpty {
                DropZoneView()
            } else {
                ImageGridView()
            }

            Divider()

            SidebarView()
                .frame(width: 420)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !appState.buckets.isEmpty {
                    RatioFilterChips()
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if !appState.images.isEmpty {
                    HStack {
                        Button { showShortcutsPopover.toggle() } label: {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(FCPToolbarButtonStyle())
                        .popover(isPresented: $showShortcutsPopover) {
                            KeyboardShortcutsContentView()
                                .padding()
                        }
                        .help("Keyboard Shortcuts")

                        Button {
                            appState.showImportPanel()
                        } label: {
                            Image(systemName: "plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(FCPToolbarButtonStyle())

                        Button {
                            if appState.selectedImageIDs.isEmpty {
                                showClearAllConfirmation = true
                            } else {
                                appState.removeImages(ids: appState.selectedImageIDs)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(FCPToolbarButtonStyle())
                        .help(appState.selectedImageIDs.isEmpty
                              ? "Clear all images"
                              : "Remove \(appState.selectedImageIDs.count) selected")
                        .confirmationDialog(
                            "Clear all images?",
                            isPresented: $showClearAllConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Clear All", role: .destructive) { appState.clearAll() }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will remove all \(appState.images.count) images from the list. Files on disk are not affected.")
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .toolbarRole(.editor)
        .toolbarBackground(Color(white: 0.10), for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            appState.addImages(from: [url])
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }
}

// MARK: - Sidebar View
//
// v1: Export-only sidebar. Wave 4 replaces this with the analyze flow (histogram picker + Auto).

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            Form {
                if !appState.buckets.isEmpty {
                    Section {
                        HistogramView()
                    }
                }

                Section {
                    ExportFormatView()
                }

                Section {
                    QualityNamingView()
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(Color(nsColor: .windowBackgroundColor))

            ExportFooterView()
        }
    }
}

struct RatioFilterChips: View {
    @Environment(AppState.self) private var appState

    /// Top-N buckets by count are pinned to the chip strip on initial analysis. The user
    /// can promote any overflow bucket via the +menu; that promotion replaces the rightmost
    /// chip slot, so the strip stays at exactly N. Chip order is stable across filter
    /// toggles — a chip clicked never moves, which preserves the user's spatial map.
    static let maxVisible = 10

    private var visibleBuckets: [AspectRatioBucket] {
        appState.chipOrder.compactMap { id in
            appState.buckets.first(where: { $0.id == id })
        }
    }

    private var overflowBuckets: [AspectRatioBucket] {
        let visibleIDs = Set(appState.chipOrder)
        return appState.buckets.filter { !visibleIDs.contains($0.id) }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(visibleBuckets) { bucket in
                chip(for: bucket)
            }

            if !overflowBuckets.isEmpty {
                Menu {
                    ForEach(overflowBuckets) { bucket in
                        Button {
                            appState.promoteToChips(bucket.id, max: Self.maxVisible)
                            appState.toggleFilter(for: bucket)
                        } label: {
                            if appState.isFilterActive(for: bucket) {
                                Label("\(bucket.label) — \(bucket.items.count)×", systemImage: "checkmark")
                            } else {
                                Text("\(bucket.label) — \(bucket.items.count)×")
                            }
                        }
                    }
                } label: {
                    Text("+\(overflowBuckets.count)")
                        .font(.system(size: 11, weight: .medium))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("\(overflowBuckets.count) more aspect ratio\(overflowBuckets.count == 1 ? "" : "s")")
            }

            if !appState.ratioFilter.isEmpty {
                Button {
                    appState.clearFilter()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(FCPToolbarButtonStyle(isOn: false))
                .help("Clear filter")
            }
        }
        .buttonStyle(.borderless)
    }

    @ViewBuilder
    private func chip(for bucket: AspectRatioBucket) -> some View {
        let active = appState.isFilterActive(for: bucket)
        Button {
            appState.toggleFilter(for: bucket)
        } label: {
            HStack(spacing: 4) {
                Text(bucket.label)
                    .font(.system(size: 11, weight: .medium))
                Text("\(bucket.items.count)×")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(FCPToolbarButtonStyle(isOn: active))
        .help("Filter grid to \(bucket.label) (\(bucket.items.count) images)")
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .frame(width: 1000, height: 700)
}
