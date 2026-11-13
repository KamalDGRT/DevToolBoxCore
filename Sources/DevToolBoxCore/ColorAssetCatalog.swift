import Foundation

public enum ColorAssetCatalogError: Error, Equatable {
    case notADirectory(path: String)
}

/// Reads every `.colorset` under an `.xcassets` directory.
public enum ColorAssetCatalog {
    private static let colorsetExtension = "colorset"
    private static let contentsFileName = "Contents.json"
    private static let byteMax = 255.0
    private static let hexPrefixLength = 2

    public static func load(from catalogURL: URL) throws -> [ColorAsset] {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: catalogURL.path,
            isDirectory: &isDirectory
        )
        guard exists, isDirectory.boolValue else {
            throw ColorAssetCatalogError.notADirectory(path: catalogURL.path)
        }

        let enumerator = FileManager.default.enumerator(
            at: catalogURL,
            includingPropertiesForKeys: nil
        )
        var assets: [ColorAsset] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == colorsetExtension,
                  let color = try parseColorset(at: url) else {
                continue
            }
            assets.append(ColorAsset(
                name: url.deletingPathExtension().lastPathComponent,
                folderPath: relativeFolder(of: url, in: catalogURL),
                catalogName: catalogURL.lastPathComponent,
                color: color
            ))
        }
        return assets.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Prefers the universal (no `appearances`) entry over dark/high-contrast.
    static func parseColorset(at colorsetURL: URL) throws -> RGBColor? {
        let contentsURL = colorsetURL.appendingPathComponent(contentsFileName)
        guard FileManager.default.fileExists(atPath: contentsURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: contentsURL)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let entries = (json as? [String: Any])?["colors"]
                as? [[String: Any]] else {
            return nil
        }
        let universal = entries.first { $0["appearances"] == nil }
        guard let entry = universal ?? entries.first,
              let colorData = entry["color"] as? [String: Any],
              let components = colorData["components"] as? [String: Any] else {
            return nil
        }
        return RGBColor(
            red: component(components["red"]),
            green: component(components["green"]),
            blue: component(components["blue"]),
            alpha: components["alpha"] == nil ? 1.0 : component(components["alpha"])
        )
    }

    private static func relativeFolder(of colorsetURL: URL, in catalogURL: URL) -> String {
        let parent = colorsetURL.deletingLastPathComponent().resolvingSymlinksInPath().path
        let root = catalogURL.resolvingSymlinksInPath().path
        guard parent != root else { return "" }
        return parent.replacingOccurrences(of: root + "/", with: "")
    }

    /// Accepts `"0xFF"`, `"0.5"`, `"128"`, or a JSON number; returns 0...1.
    private static func component(_ raw: Any?) -> Double {
        if let text = raw as? String {
            if text.lowercased().hasPrefix("0x"),
               let value = Int(text.dropFirst(hexPrefixLength), radix: 16) {
                return Double(value) / byteMax
            }
            if let value = Double(text) { return normalize(value) }
        } else if let value = raw as? Double {
            return normalize(value)
        } else if let value = raw as? Int {
            return normalize(Double(value))
        }
        return 0.0
    }

    private static func normalize(_ value: Double) -> Double {
        value > 1.0 ? value / byteMax : value
    }
}
