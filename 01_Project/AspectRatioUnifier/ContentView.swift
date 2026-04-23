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
                if !appState.images.isEmpty {
                    ZoomPicker(selection: Binding(
                        get: { appState.zoomMode },
                        set: { appState.zoomMode = $0 }
                    ))
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

#Preview {
    ContentView()
        .environment(AppState())
        .frame(width: 1000, height: 700)
}
