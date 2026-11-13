import Foundation

public struct ColorMatch: Equatable, Sendable {
    public let asset: ColorAsset
    public let deltaE: Double

    /// Delta E below 1 is imperceptible; matches the app's "perfect" band.
    public var isExact: Bool { deltaE < NearestColorFinder.exactDeltaEThreshold }
}

public enum NearestColorFinder {
    public static let exactDeltaEThreshold = 1.0

    public static func nearest(
        to target: RGBColor,
        in assets: [ColorAsset],
        limit: Int
    ) -> [ColorMatch] {
        assets
            .map { ColorMatch(
                asset: $0,
                deltaE: ColorDistance.deltaE(target, $0.color)
            ) }
            .sorted { $0.deltaE < $1.deltaE }
            .prefix(max(limit, 0))
            .map { $0 }
    }
}
