import Foundation

/// sRGB color with components normalized to 0.0...1.0.
public struct SRGBColor: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    private static let byteMax = 255.0
    private static let byteRange = 0...255
    private static let alphaRange = 0.0...1.0
    private static let shorthandHexDigitCounts: Set<Int> = [3, 4]
    private static let rgbHexDigitCount = 6
    private static let rgbaHexDigitCount = 8
    private static let hexRadix = 16
    private static let byteMask: UInt64 = 0xFF
    private static let bitsPerByte: UInt64 = 8

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Builds a color from 0...255 byte components. Nil if any value is out of range.
    public init?(redByte: Int, greenByte: Int, blueByte: Int, alpha: Double = 1.0) {
        guard [redByte, greenByte, blueByte].allSatisfy(Self.byteRange.contains),
              Self.alphaRange.contains(alpha) else {
            return nil
        }
        self.init(
            red: Double(redByte) / Self.byteMax,
            green: Double(greenByte) / Self.byteMax,
            blue: Double(blueByte) / Self.byteMax,
            alpha: alpha
        )
    }

    /// Parses `#RGB`, `#RGBA`, `#RRGGBB` or `#RRGGBBAA` (hash optional,
    /// surrounding whitespace ignored). Returns nil for any other shape.
    public init?(hex: String) {
        var digits = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if digits.hasPrefix("#") { digits.removeFirst() }
        guard digits.allSatisfy(\.isHexDigit) else { return nil }
        if Self.shorthandHexDigitCounts.contains(digits.count) {
            digits = digits.map { "\($0)\($0)" }.joined()
        }
        guard digits.count == Self.rgbHexDigitCount
                || digits.count == Self.rgbaHexDigitCount,
              let value = UInt64(digits, radix: Self.hexRadix) else {
            return nil
        }
        let hasAlpha = digits.count == Self.rgbaHexDigitCount
        let rgb = hasAlpha ? value >> Self.bitsPerByte : value
        self.init(
            red: Self.component(rgb, shift: 2 * Self.bitsPerByte),
            green: Self.component(rgb, shift: Self.bitsPerByte),
            blue: Self.component(rgb, shift: 0),
            alpha: hasAlpha ? Self.component(value, shift: 0) : 1.0
        )
    }

    public var hexString: String {
        String(
            format: "#%02X%02X%02X",
            Self.byte(red),
            Self.byte(green),
            Self.byte(blue)
        )
    }

    public var rgbString: String {
        "RGB(\(Self.byte(red)), \(Self.byte(green)), \(Self.byte(blue)))"
    }

    public static let white = SRGBColor(red: 1.0, green: 1.0, blue: 1.0)
    public static let black = SRGBColor(red: 0.0, green: 0.0, blue: 0.0)

    /// Alpha-blends this color over `background`; the result is fully opaque.
    /// The background's own alpha is ignored (treated as opaque).
    public func composited(over background: SRGBColor) -> SRGBColor {
        SRGBColor(
            red: red * alpha + background.red * (1 - alpha),
            green: green * alpha + background.green * (1 - alpha),
            blue: blue * alpha + background.blue * (1 - alpha)
        )
    }

    /// Composites this color over opaque white; the result is fully opaque.
    public var flattenedOnWhite: SRGBColor { composited(over: .white) }

    private static func component(_ value: UInt64, shift: UInt64) -> Double {
        Double((value >> shift) & byteMask) / byteMax
    }

    private static func byte(_ component: Double) -> Int {
        Int((component * byteMax).rounded())
    }
}
