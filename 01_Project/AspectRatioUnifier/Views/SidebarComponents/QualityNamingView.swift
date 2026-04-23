import SwiftUI

// MARK: - Quality & Naming

struct QualityNamingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        // Quality slider (for JPEG/HEIC/WebP)
        if appState.exportSettings.format.supportsCompression {
            LabeledContent("Quality") {
                HStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { appState.exportSettings.quality },
                        set: { appState.exportSettings.quality = $0; appState.markCustomSettings() }
                    ), in: 0.1...1.0, step: 0.05)
                    .frame(maxWidth: 120)
                    Text("\(Int(appState.exportSettings.quality * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }

        // Suffix field (when using Keep Original naming)
        if appState.exportSettings.renameSettings.mode == .keepOriginal {
            LabeledContent("Suffix") {
                TextField("", text: Binding(
                    get: { appState.exportSettings.suffix },
                    set: { appState.exportSettings.suffix = $0; appState.markCustomSettings() }
                ), prompt: Text("_ratioed"))
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
            }
        }

        // Pattern field (when using Pattern naming)
        if appState.exportSettings.renameSettings.mode == .pattern {
            LabeledContent("Pattern") {
                TextField("", text: Binding(
                    get: { appState.exportSettings.renameSettings.pattern },
                    set: { appState.exportSettings.renameSettings.pattern = $0; appState.markCustomSettings() }
                ), prompt: Text("{name}_{n}"))
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .font(.system(.body, design: .monospaced))
            }

            // Token buttons
            LabeledContent("Tokens") {
                HStack(spacing: 4) {
                    ForEach(RenameSettings.availableTokens, id: \.token) { token in
                        Button(token.token) {
                            appState.exportSettings.renameSettings.pattern += token.token
                            appState.markCustomSettings()
                        }
                        .help(token.description)
                    }
                }
                .controlSize(.mini)
                .buttonStyle(.bordered)
            }
        }
    }
}
