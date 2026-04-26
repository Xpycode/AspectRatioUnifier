import SwiftUI

struct HistogramView: View {
    @Environment(AppState.self) private var appState

    private let barHeight: CGFloat = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            bars
            readout
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Label("Aspect Ratios", systemImage: "chart.bar.xaxis")
                .font(.callout.weight(.medium))
            Spacer()
            Text("\(appState.buckets.count) bucket(s), \(totalImageCount) image(s)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var bars: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(appState.buckets) { bucket in
                bar(for: bucket)
            }
        }
        .frame(height: barHeight + 32)   // bar + label rows
    }

    private func bar(for bucket: AspectRatioBucket) -> some View {
        let isSelected = appState.selectedBucketID == bucket.id
        let fraction = maxCount == 0 ? 0 : CGFloat(bucket.items.count) / CGFloat(maxCount)
        return VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: barHeight)
                RoundedRectangle(cornerRadius: 3)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.6))
                    .frame(height: max(2, barHeight * fraction))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            Text("\(bucket.items.count)×")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(isSelected ? .primary : .secondary)
            Text(bucket.label)
                .font(.caption2)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .onTapGesture { appState.selectedBucketID = bucket.id }
        .help("\(bucket.items.count) image(s) at \(bucket.label), median \(Int(bucket.medianSize.width))×\(Int(bucket.medianSize.height))")
    }

    @ViewBuilder
    private var readout: some View {
        if let bucket = appState.selectedBucket, let target = appState.targetSize {
            @Bindable var state = appState
            VStack(alignment: .leading, spacing: 6) {
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target committed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $state.targetSizeStrategy) {
                            ForEach(TargetSizeStrategy.allCases) { strategy in
                                Text(strategy.label)
                                    .tag(strategy)
                                    .help(strategy.help)
                            }
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.small)
                        .labelsHidden()
                        Text("\(Int(target.width)) × \(Int(target.height))")
                            .font(.system(.callout, design: .monospaced))
                        Text(bucket.label + (bucket.isNamedPreset ? "" : " (custom)"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        } else {
            Text("Tap a bar to pick the target ratio.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var maxCount: Int {
        appState.buckets.map(\.items.count).max() ?? 0
    }

    private var totalImageCount: Int {
        appState.buckets.reduce(0) { $0 + $1.items.count }
    }
}
