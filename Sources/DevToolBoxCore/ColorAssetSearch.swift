import Foundation

/// Text search over loaded assets, matching the app's Asset Searcher.
public enum ColorAssetSearch {
    /// Case-insensitive substring match on name, hex, RGB string or folder.
    /// An empty query returns every asset.
    public static func matching(_ query: String, in assets: [ColorAsset]) -> [ColorAsset] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return assets }
        return assets.filter { asset in
            [
                asset.name,
                asset.color.hexString,
                asset.color.rgbString,
                asset.displayFolderPath
            ].contains { $0.lowercased().contains(needle) }
        }
    }
}
