import Foundation
import Testing
@testable import DevToolBoxCore

struct SRGBColorTests {
    @Test func parsesHexWithAndWithoutHash() {
        let withHash = SRGBColor(hex: "#F26522")
        let withoutHash = SRGBColor(hex: "f26522")
        #expect(withHash == withoutHash)
        #expect(withHash?.hexString == "#F26522")
    }

    @Test func rejectsMalformedHex() {
        #expect(SRGBColor(hex: "#FFFFF") == nil)
        #expect(SRGBColor(hex: "#+12345") == nil)
        #expect(SRGBColor(hex: "#GGGGGG") == nil)
        #expect(SRGBColor(hex: "") == nil)
    }
}

struct SRGBColorFormatTests {
    @Test func expandsShorthandHex() {
        #expect(SRGBColor(hex: "#F80") == SRGBColor(hex: "#FF8800"))
        #expect(SRGBColor(hex: "#F80A") == SRGBColor(hex: "#FF8800AA"))
    }

    @Test func parsesEightDigitHexAlpha() throws {
        let color = try #require(SRGBColor(hex: " #FF000080 "))
        #expect(color.hexString == "#FF0000")
        #expect(abs(color.alpha - 128.0 / 255.0) < 1e-9, "alpha \(color.alpha)")
    }

    @Test func validatesByteInit() {
        #expect(SRGBColor(redByte: 256, greenByte: 0, blueByte: 0) == nil)
        #expect(SRGBColor(redByte: 0, greenByte: -1, blueByte: 0) == nil)
        #expect(SRGBColor(redByte: 0, greenByte: 0, blueByte: 0, alpha: 1.5) == nil)
        #expect(SRGBColor(redByte: 255, greenByte: 0, blueByte: 0, alpha: 0.5)?.alpha == 0.5)
    }

    @Test func formatsRGBString() throws {
        let color = try #require(SRGBColor(hex: "#0061A5"))
        #expect(color.rgbString == "RGB(0, 97, 165)")
    }

    @Test func flattensAlphaOntoWhite() throws {
        let halfBlack = SRGBColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        #expect(halfBlack.flattenedOnWhite.hexString == "#808080")
        #expect(halfBlack.flattenedOnWhite.alpha == 1.0)
        let opaque = try #require(SRGBColor(hex: "#123456"))
        #expect(opaque.flattenedOnWhite == opaque)
    }
}

struct ColorDistanceTests {
    @Test func identicalColorsHaveZeroDistance() throws {
        let color = try #require(SRGBColor(hex: "#004E7D"))
        #expect(ColorDistance.deltaE(color, color) == 0)
    }

    @Test func blackToWhiteIsAbout100() throws {
        let black = try #require(SRGBColor(hex: "#000000"))
        let white = try #require(SRGBColor(hex: "#FFFFFF"))
        let distance = ColorDistance.deltaE(black, white)
        #expect(abs(distance - 100) < 0.5, "got \(distance)")
    }

    @Test func nearbyColorIsCloserThanFarColor() throws {
        let target = try #require(SRGBColor(hex: "#D0D0D0"))
        let near = try #require(SRGBColor(hex: "#D1D3D6"))
        let far = try #require(SRGBColor(hex: "#004E7D"))
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
        let target = try #require(SRGBColor(hex: "#0061A5"))
        let matches = NearestColorFinder.nearest(to: target, in: assets, limit: 1)
        #expect(matches.count == 1)
        #expect(matches.first?.asset.name == "darkBlue")
        #expect(matches.first?.isExact == true)
    }
}

struct CompositingTests {
    @Test func compositesOverBlackAndCustomBackground() throws {
        let halfWhite = SRGBColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        #expect(halfWhite.composited(over: .black).hexString == "#808080")
        let blue = try #require(SRGBColor(hex: "#0000FF"))
        let result = halfWhite.composited(over: blue)
        #expect(result.hexString == "#8080FF", "got \(result.hexString)")
        #expect(result.alpha == 1.0)
    }

    @Test func opaqueColorIgnoresBackground() throws {
        let opaque = try #require(SRGBColor(hex: "#123456"))
        #expect(opaque.composited(over: .black) == opaque)
    }
}

private func asset(_ name: String, _ hex: String, folder: String = "") -> ColorAsset {
    ColorAsset(
        name: name,
        folderPath: folder,
        catalogName: "T.xcassets",
        color: SRGBColor(hex: hex)!
    )
}

struct ColorAssetSearchTests {
    private let assets = [
        asset("brandBlue", "#0061A5", folder: "Brand"),
        asset("errorRed", "#FF0000"),
        asset("dangerRed", "#FF0000", folder: "Brand/Alerts")
    ]

    @Test func matchesNameHexRGBAndFolder() {
        #expect(ColorAssetSearch.matching("BLUE", in: assets).map(\.name) == ["brandBlue"])
        #expect(ColorAssetSearch.matching("ff0000", in: assets).count == 2)
        #expect(ColorAssetSearch.matching("rgb(0, 97", in: assets).map(\.name) == ["brandBlue"])
        #expect(ColorAssetSearch.matching("alerts", in: assets).map(\.name) == ["dangerRed"])
        #expect(ColorAssetSearch.matching("root", in: assets).map(\.name) == ["errorRed"])
    }

    @Test func emptyQueryReturnsAll() {
        #expect(ColorAssetSearch.matching("  ", in: assets).count == 3)
    }

    @Test func noMatchReturnsEmpty() {
        #expect(ColorAssetSearch.matching("zzz", in: assets).isEmpty)
    }
}

struct DuplicateColorFinderTests {
    @Test func groupsSameHexSortedAndSkipsUniques() {
        let groups = DuplicateColorFinder.groups(in: [
            asset("zeta", "#FF0000"),
            asset("alpha", "#FF0000"),
            asset("solo", "#00FF00"),
            asset("b", "#0000FF"),
            asset("a", "#0000FF")
        ])
        #expect(groups.map(\.hex) == ["#0000FF", "#FF0000"])
        #expect(groups[1].assets.map(\.name) == ["alpha", "zeta"])
    }

    @Test func noDuplicatesGivesEmpty() {
        #expect(DuplicateColorFinder.groups(in: [asset("a", "#000000"), asset("b", "#111111")]).isEmpty)
    }
}
