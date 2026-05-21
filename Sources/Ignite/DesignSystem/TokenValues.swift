//
//  TokenValues.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// A color value in the design system.
public struct ColorValue: TokenValue, Sendable {
    public let red: Int
    public let green: Int
    public let blue: Int
    public let alpha: Double

    public var cssValue: String {
        alpha < 1.0
            ? "rgba(\(red), \(green), \(blue), \(alpha))"
            : "rgb(\(red), \(green), \(blue))"
    }

    public init(red: Int, green: Int, blue: Int, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleaned.count == 6,
              let value = UInt32(cleaned, radix: 16) else {
            self.init(red: 0, green: 0, blue: 0)
            return
        }
        self.init(
            red: Int((value >> 16) & 0xFF),
            green: Int((value >> 8) & 0xFF),
            blue: Int(value & 0xFF)
        )
    }
}

/// A spacing value in the design system.
public struct SpacingValue: TokenValue, Sendable {
    public let rem: Double

    public var cssValue: String { "\(rem)rem" }

    public init(rem: Double) {
        self.rem = rem
    }

    /// Creates a spacing token from a scale step (1 = 0.25rem, 4 = 1rem, 16 = 4rem).
    public static func scale(_ step: Int) -> DesignToken<SpacingValue> {
        DesignToken(
            name: "\(step)",
            category: .spacing,
            value: SpacingValue(rem: Double(step) * 0.25)
        )
    }
}

/// A typography value combining font properties.
public struct TypographyValue: TokenValue, Sendable {
    public let fontFamily: String
    public let fontSize: Double
    public let fontWeight: Int
    public let lineHeight: Double
    public let letterSpacing: Double

    public var cssValue: String {
        "\(fontWeight) \(fontSize)rem/\(lineHeight) \(fontFamily)"
    }

    public init(fontFamily: String, fontSize: Double, fontWeight: Int, lineHeight: Double, letterSpacing: Double) {
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
    }
}

/// A shadow value for elevation.
public struct ShadowValue: TokenValue, Sendable {
    public let x: Double
    public let y: Double
    public let blur: Double
    public let spread: Double
    public let color: ColorValue

    public var cssValue: String {
        "\(x)px \(y)px \(blur)px \(spread)px \(color.cssValue)"
    }

    public init(x: Double, y: Double, blur: Double, spread: Double, color: ColorValue) {
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
        self.color = color
    }
}

/// A border radius value.
public struct RadiusValue: TokenValue, Sendable {
    public let rem: Double
    public var cssValue: String { "\(rem)rem" }

    public init(rem: Double) {
        self.rem = rem
    }
}

/// A responsive breakpoint value.
public struct BreakpointValue: TokenValue, Sendable {
    public let minWidth: Int
    public var cssValue: String { "\(minWidth)px" }

    public init(minWidth: Int) {
        self.minWidth = minWidth
    }
}
