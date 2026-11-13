import Foundation

/// sRGB color with components normalized to 0.0...1.0.
public struct RGBColor: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    private static let byteMax = 255.0
    private static let hexDigitsPerColor = 6
    private static let hexRadix = 16

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Builds a color from 0...255 byte components.
    public init(redByte: Int, greenByte: Int, blueByte: Int) {
        self.init(
            red: Double(redByte) / Self.byteMax,
            green: Double(greenByte) / Self.byteMax,
            blue: Double(blueByte) / Self.byteMax
        )
    }

    /// Parses `#RRGGBB` or `RRGGBB`. Returns nil for any other shape.
    public init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == Self.hexDigitsPerColor,
              let value = Int(digits, radix: Self.hexRadix) else {
            return nil
        }
        self.init(
            redByte: (value >> 16) & 0xFF,
            greenByte: (value >> 8) & 0xFF,
            blueByte: value & 0xFF
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

    private static func byte(_ component: Double) -> Int {
        Int((component * byteMax).rounded())
    }
}
