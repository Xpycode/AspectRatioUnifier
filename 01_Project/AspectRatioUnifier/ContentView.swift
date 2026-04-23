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

    var body: some View {
        HStack(spacing: 4) {
            ForEach(appState.buckets) { bucket in
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
}

#Preview {
    ContentView()
        .environment(AppState())
        .frame(width: 1000, height: 700)
}
