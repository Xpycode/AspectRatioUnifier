import SwiftUI

struct ImageInfoView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Images:")
                Spacer()
                Text("\(appState.images.count)")
                    .foregroundStyle(.secondary)
            }
            .font(.callout)

            if let majority = appState.majorityResolution {
                HStack {
                    Text("Resolution:")
                    Spacer()
                    Text("\(Int(majority.width)) × \(Int(majority.height))")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
            }

        }
    }
}
