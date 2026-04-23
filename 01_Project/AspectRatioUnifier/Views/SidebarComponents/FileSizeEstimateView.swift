import SwiftUI

// MARK: - File Size Estimate

struct FileSizeEstimateView: View {
    @Environment(AppState.self) private var appState

    private var batchEstimate: FileSizeEstimate {
        FileSizeEstimator.estimate(
            images: appState.images,
            exportSettings: appState.exportSettings
        )
    }

    private var activeFileEstimate: FileSizeEstimate? {
        guard let activeImage = appState.activeImage else { return nil }
        return FileSizeEstimator.estimate(
            images: [activeImage],
            exportSettings: appState.exportSettings
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            if let fileEstimate = activeFileEstimate {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    HStack(spacing: 4) {
                        Text("\(Int(fileEstimate.percentage))%")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(percentageColor(for: fileEstimate.percentage))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(percentageColor(for: fileEstimate.percentage).opacity(0.15)))

                        Text("\(fileEstimate.estimatedTotal.formattedFileSize)")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if activeFileEstimate != nil && appState.images.count > 1 {
                Divider()
                    .frame(height: 28)
            }

            if appState.images.count > 1 {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Batch (\(appState.images.count))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    HStack(spacing: 4) {
                        Text("\(Int(batchEstimate.percentage))%")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(percentageColor(for: batchEstimate.percentage))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(percentageColor(for: batchEstimate.percentage).opacity(0.15)))

                        Text("\(batchEstimate.estimatedTotal.formattedFileSize)")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            savingsIndicator(for: batchEstimate)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor)))
    }

    @ViewBuilder
    private func savingsIndicator(for estimate: FileSizeEstimate) -> some View {
        if estimate.savings > 0 {
            HStack(spacing: 2) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("−\(estimate.savings.formattedFileSize)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.green)
            }
        } else if estimate.savings < 0 {
            HStack(spacing: 2) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("+\((-estimate.savings).formattedFileSize)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func percentageColor(for percentage: Double) -> Color {
        if percentage < 50 {
            return .green
        } else if percentage < 100 {
            return .blue
        } else {
            return .orange
        }
    }
}
