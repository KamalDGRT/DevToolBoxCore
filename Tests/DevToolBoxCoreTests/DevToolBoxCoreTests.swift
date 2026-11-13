import Foundation
import Testing
@testable import DevToolBoxCore

struct RGBColorTests {
    @Test func parsesHexWithAndWithoutHash() {
        let withHash = RGBColor(hex: "#F26522")
        let withoutHash = RGBColor(hex: "f26522")
        #expect(withHash == withoutHash)
        #expect(withHash?.hexString == "#F26522")
    }

    @Test func rejectsMalformedHex() {
        #expect(RGBColor(hex: "#FFF") == nil)
        #expect(RGBColor(hex: "#GGGGGG") == nil)
        #expect(RGBColor(hex: "") == nil)
    }
}

struct ColorDistanceTests {
    @Test func identicalColorsHaveZeroDistance() throws {
        let color = try #require(RGBColor(hex: "#004E7D"))
        #expect(ColorDistance.deltaE(color, color) == 0)
    }

    @Test func blackToWhiteIsAbout100() throws {
        let black = try #require(RGBColor(hex: "#000000"))
        let white = try #require(RGBColor(hex: "#FFFFFF"))
        let distance = ColorDistance.deltaE(black, white)
        #expect(abs(distance - 100) < 0.5, "got \(distance)")
    }

    @Test func nearbyColorIsCloserThanFarColor() throws {
        let target = try #require(RGBColor(hex: "#D0D0D0"))
        let near = try #require(RGBColor(hex: "#D1D3D6"))
        let far = try #require(RGBColor(hex: "#004E7D"))
        #expect(
            ColorDistance.deltaE(target, near)
                < ColorDistance.deltaE(target, far)
        )
    }
}

struct ColorAssetCatalogTests {
    private func makeCatalog() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Test.xcassets")
        try writeColorset(
            named: "darkBlue", folder: root,
            entries: [universal(red: "0x00", green: "0x61", blue: "0xA5")]
        )
        try writeColorset(
            named: "adaptive", folder: root.appendingPathComponent("Group"),
            entries: [
                dark(red: "0.0", green: "0.0", blue: "0.0"),
                universal(red: "1.000", green: "1.000", blue: "1.000")
            ]
        )
        return root
    }

    private func universal(red: String, green: String, blue: String) -> [String: Any] {
        ["color": ["color-space": "srgb", "components": [
            "red": red, "green": green, "blue": blue, "alpha": "1.000"
        ]]]
    }

    private func dark(red: String, green: String, blue: String) -> [String: Any] {
        var entry = universal(red: red, green: green, blue: blue)
        entry["appearances"] = [["appearance": "luminosity", "value": "dark"]]
        return entry
    }

    private func writeColorset(
        named name: String, folder: URL, entries: [[String: Any]]
    ) throws {
        let colorset = folder.appendingPathComponent("\(name).colorset")
        try FileManager.default.createDirectory(
            at: colorset, withIntermediateDirectories: true
        )
        let data = try JSONSerialization.data(withJSONObject: ["colors": entries])
        try data.write(to: colorset.appendingPathComponent("Contents.json"))
    }

    @Test func loadsColorsetsAndPrefersUniversalEntry() throws {
        let catalog = try makeCatalog()
        let assets = try ColorAssetCatalog.load(from: catalog)

        #expect(assets.map(\.name) == ["adaptive", "darkBlue"])
        let darkBlue = try #require(assets.first { $0.name == "darkBlue" })
        #expect(darkBlue.color.hexString == "#0061A5")
        #expect(darkBlue.folderPath.isEmpty)
        let adaptive = try #require(assets.first { $0.name == "adaptive" })
        #expect(adaptive.color.hexString == "#FFFFFF", "dark entry must be skipped")
        #expect(adaptive.folderPath == "Group")
    }

    @Test func throwsWhenPathIsNotADirectory() {
        let missing = URL(fileURLWithPath: "/nonexistent/Nope.xcassets")
        #expect(throws: ColorAssetCatalogError.notADirectory(path: missing.path)) {
            try ColorAssetCatalog.load(from: missing)
        }
    }

    @Test func nearestReturnsExactMatchFirst() throws {
        let assets = try ColorAssetCatalog.load(from: makeCatalog())
        let target = try #require(RGBColor(hex: "#0061A5"))
        let matches = NearestColorFinder.nearest(to: target, in: assets, limit: 1)
        #expect(matches.count == 1)
        #expect(matches.first?.asset.name == "darkBlue")
        #expect(matches.first?.isExact == true)
    }
}
