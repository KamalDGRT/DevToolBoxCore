import Foundation

/// Two or more colorsets that resolve to the same hex value.
public struct DuplicateColorGroup: Equatable, Sendable {
    public let hex: String
    public let assets: [ColorAsset]
}

public enum DuplicateColorFinder {
    /// Groups assets by hex, keeps groups with 2+ members. Assets are sorted by
    /// name, groups by hex.
    public static func groups(in assets: [ColorAsset]) -> [DuplicateColorGroup] {
        Dictionary(grouping: assets, by: { $0.color.hexString })
            .filter { $0.value.count > 1 }
            .map { hex, members in
                DuplicateColorGroup(
                    hex: hex,
                    assets: members.sorted {
                        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                )
            }
            .sorted { $0.hex < $1.hex }
    }
}
