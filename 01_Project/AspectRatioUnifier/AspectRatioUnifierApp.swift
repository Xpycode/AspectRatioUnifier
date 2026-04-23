import SwiftUI
import AppKit
import os

@main
struct AspectRatioUnifierApp: App {
    @State private var appState = AppState()
    @State private var isCLIMode = false

    private let updateController = UpdateController()

    init() {
        if CLIHandler.hasArguments() {
            isCLIMode = true
            Task {
                let exitCode = await CLIHandler.run()
                exit(exitCode)
            }
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1200, minHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updateController.checkForUpdates()
                }
                .disabled(!updateController.canCheckForUpdates)
            }

            CommandGroup(replacing: .newItem) {
                Button("Import Images...") {
                    appState.showImportPanel()
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Export...") {
                    showExportPanel()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(!appState.canExport)

                Divider()

                Button("Clear All") {
                    appState.clearAll()
                }
                .disabled(appState.images.isEmpty)
            }

            CommandGroup(after: .pasteboard) {
                Divider()

                Button("Select All") {
                    appState.selectedImageIDs = Set(appState.images.map { $0.id })
                }
                .keyboardShortcut("a", modifiers: .command)
                .disabled(appState.images.isEmpty)

                Button("Deselect All") {
                    appState.selectedImageIDs.removeAll()
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .disabled(appState.selectedImageIDs.isEmpty)
            }

            CommandMenu("Image") {
                Button("Previous Image") {
                    appState.selectPreviousImage()
                }
                .keyboardShortcut(.upArrow, modifiers: .command)
                .disabled(appState.images.count < 2)

                Button("Next Image") {
                    appState.selectNextImage()
                }
                .keyboardShortcut(.downArrow, modifiers: .command)
                .disabled(appState.images.count < 2)

                Divider()

                Button("Remove Selected") {
                    appState.removeImages(ids: appState.selectedImageIDs.isEmpty
                        ? (appState.activeImage.map { Set([$0.id]) } ?? Set())
                        : appState.selectedImageIDs)
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(appState.activeImage == nil && appState.selectedImageIDs.isEmpty)
            }
        }
    }

    private func showExportPanel() {
        let panel = NSOpenPanel()
        panel.title = "Choose Export Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let outputURL = panel.url else { return }

            Task { @MainActor in
                do {
                    let urls = try await appState.processAndExport(to: outputURL)
                    appState.sendExportNotification(count: urls.count)
                } catch {
                    AspectRatioUnifierLogger.ui.error("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
