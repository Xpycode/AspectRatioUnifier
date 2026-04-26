import Foundation

/// User-selectable sort dimension for the main grid. Aspect Ratio is the historical
/// default; Width/Height/Megapixels were added so the user can hunt the small images
/// that drag down the Min target-size strategy.
enum GridSortDimension: String, CaseIterable, Identifiable, Codable {
    case ratio, width, height, megapixels

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ratio:      "Aspect Ratio"
        case .width:      "Width"
        case .height:     "Height"
        case .megapixels: "Megapixels"
        }
    }
}

/// Persistent grid sort state. Codable so it round-trips through UserDefaults via
/// JSONEncoder/Decoder — same persistence shape as ExportSettings.userProfiles.
struct GridSort: Equatable, Codable {
    var dimension: GridSortDimension = .ratio
    var reversed: Bool = false

    /// Returns the input sorted by the chosen dimension, applying the reversed flag,
    /// with a stable id-string tiebreak so equal-keyed thumbnails don't flicker.
    func apply(to images: [ImageItem]) -> [ImageItem] {
        images.sorted { a, b in
            let primary = compare(a, b)
            if primary != .orderedSame {
                let asc = primary == .orderedAscending
                return reversed ? !asc : asc
            }
            return a.id.uuidString < b.id.uuidString
        }
    }

    private func compare(_ a: ImageItem, _ b: ImageItem) -> ComparisonResult {
        let lhs: Double
        let rhs: Double
        switch dimension {
        case .ratio:
            lhs = a.aspectRatio
            rhs = b.aspectRatio
        case .width:
            lhs = a.originalSize.width
            rhs = b.originalSize.width
        case .height:
            lhs = a.originalSize.height
            rhs = b.originalSize.height
        case .megapixels:
            lhs = a.megapixels
            rhs = b.megapixels
        }
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    // MARK: - Persistence

    /// One UserDefaults key, JSON-encoded — mirrors the ExportSettings.persist() pattern.
    private static let userDefaultsKey = "AspectRatioUnifier.gridSort"

    static func load() -> GridSort {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(GridSort.self, from: data)
        else {
            return GridSort()
        }
        return decoded
    }

    func persist() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
}
