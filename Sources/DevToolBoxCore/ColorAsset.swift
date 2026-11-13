import Foundation

/// A single `.colorset` found inside an `.xcassets` catalog.
public struct ColorAsset: Equatable, Sendable {
    public let name: String
    /// Folder relative to the catalog root; empty for root-level colorsets.
    public let folderPath: String
    public let catalogName: String
    public let color: SRGBColor

    public init(
        name: String,
        folderPath: String,
        catalogName: String,
        color: SRGBColor
    ) {
        self.name = name
        self.folderPath = folderPath
        self.catalogName = catalogName
        self.color = color
    }
}
