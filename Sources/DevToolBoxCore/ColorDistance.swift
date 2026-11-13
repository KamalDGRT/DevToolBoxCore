import Foundation

/// CIE76 perceptual color difference (Delta E) in CIELAB space (D65).
public enum ColorDistance {
    private struct Lab {
        let lightness: Double
        let greenRed: Double
        let blueYellow: Double
    }

    private static let gammaThreshold = 0.04045
    private static let gammaOffset = 0.055
    private static let gammaScale = 1.055
    private static let gammaExponent = 2.4
    private static let gammaLinearDivisor = 12.92

    private static let whiteX = 0.95047
    private static let whiteY = 1.00000
    private static let whiteZ = 1.08883

    private static let labThreshold = 0.008856
    private static let labLinearSlope = 7.787
    private static let labLinearOffset = 16.0 / 116.0

    public static func deltaE(_ first: SRGBColor, _ second: SRGBColor) -> Double {
        let firstLab = lab(from: first)
        let secondLab = lab(from: second)
        let lightness = firstLab.lightness - secondLab.lightness
        let greenRed = firstLab.greenRed - secondLab.greenRed
        let blueYellow = firstLab.blueYellow - secondLab.blueYellow
        return (
            lightness * lightness
                + greenRed * greenRed
                + blueYellow * blueYellow
        ).squareRoot()
    }

    private static func lab(from color: SRGBColor) -> Lab {
        let red = linearize(color.red)
        let green = linearize(color.green)
        let blue = linearize(color.blue)

        let x = red * 0.4124564 + green * 0.3575761 + blue * 0.1804375
        let y = red * 0.2126729 + green * 0.7151522 + blue * 0.0721750
        let z = red * 0.0193339 + green * 0.1191920 + blue * 0.9503041

        let fx = labCurve(x / whiteX)
        let fy = labCurve(y / whiteY)
        let fz = labCurve(z / whiteZ)

        return Lab(
            lightness: 116.0 * fy - 16.0,
            greenRed: 500.0 * (fx - fy),
            blueYellow: 200.0 * (fy - fz)
        )
    }

    private static func linearize(_ component: Double) -> Double {
        component > gammaThreshold
            ? pow((component + gammaOffset) / gammaScale, gammaExponent)
            : component / gammaLinearDivisor
    }

    private static func labCurve(_ ratio: Double) -> Double {
        ratio > labThreshold
            ? pow(ratio, 1.0 / 3.0)
            : labLinearSlope * ratio + labLinearOffset
    }
}
