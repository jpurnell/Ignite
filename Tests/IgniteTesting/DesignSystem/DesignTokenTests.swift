//
//  DesignTokenTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for design token types and CSS generation.
@Suite("DesignToken Tests")
struct DesignTokenTests {

    // MARK: - DesignToken

    @Test("Token generates correct CSS property name")
    func tokenCSSProperty() {
        let token = DesignToken(name: "primary", category: .color, value: ColorValue(red: 255, green: 0, blue: 0))
        #expect(token.cssProperty == "--ig-color-primary")
    }

    @Test("Token generates correct CSS var reference")
    func tokenCSSVar() {
        let token = DesignToken(name: "sm", category: .spacing, value: SpacingValue(rem: 0.25))
        #expect(token.cssVar == "var(--ig-space-sm)")
    }

    // MARK: - ColorValue

    @Test("RGB color generates correct CSS")
    func colorRGB() {
        let color = ColorValue(red: 100, green: 200, blue: 50)
        #expect(color.cssValue == "rgb(100, 200, 50)")
    }

    @Test("RGBA color includes alpha")
    func colorRGBA() {
        let color = ColorValue(red: 100, green: 200, blue: 50, alpha: 0.5)
        #expect(color.cssValue == "rgba(100, 200, 50, 0.5)")
    }

    @Test("Hex initialization parses correctly")
    func colorHex() {
        let color = ColorValue(hex: "#FF6B35")
        #expect(color.red == 255)
        #expect(color.green == 107)
        #expect(color.blue == 53)
    }

    @Test("Hex without hash parses correctly")
    func colorHexNoHash() {
        let color = ColorValue(hex: "0066CC")
        #expect(color.red == 0)
        #expect(color.green == 102)
        #expect(color.blue == 204)
    }

    @Test("Invalid hex defaults to black")
    func colorHexInvalid() {
        let color = ColorValue(hex: "invalid")
        #expect(color.red == 0)
        #expect(color.green == 0)
        #expect(color.blue == 0)
    }

    // MARK: - SpacingValue

    @Test("Spacing generates rem CSS")
    func spacingCSS() {
        let spacing = SpacingValue(rem: 1.5)
        #expect(spacing.cssValue == "1.5rem")
    }

    @Test("Spacing scale generates expected values")
    func spacingScale() {
        let step4 = SpacingValue.scale(4)
        #expect(step4.value.rem == 1.0)
        #expect(step4.name == "4")
    }

    // MARK: - TypographyValue

    @Test("Typography generates CSS shorthand")
    func typographyCSS() {
        let typo = TypographyValue(
            fontFamily: "Inter, sans-serif",
            fontSize: 1.0,
            fontWeight: 400,
            lineHeight: 1.5,
            letterSpacing: 0.0
        )
        #expect(typo.cssValue == "400 1.0rem/1.5 Inter, sans-serif")
    }

    // MARK: - ShadowValue

    @Test("Shadow generates correct CSS")
    func shadowCSS() {
        let shadow = ShadowValue(
            x: 0, y: 2, blur: 4, spread: 0,
            color: ColorValue(red: 0, green: 0, blue: 0, alpha: 0.1)
        )
        #expect(shadow.cssValue.contains("0.0px 2.0px 4.0px 0.0px"))
        #expect(shadow.cssValue.contains("rgba(0, 0, 0, 0.1)"))
    }

    // MARK: - RadiusValue

    @Test("Radius generates rem CSS")
    func radiusCSS() {
        let radius = RadiusValue(rem: 0.5)
        #expect(radius.cssValue == "0.5rem")
    }

    // MARK: - BreakpointValue

    @Test("Breakpoint generates px CSS")
    func breakpointCSS() {
        let bp = BreakpointValue(minWidth: 768)
        #expect(bp.cssValue == "768px")
    }

    // MARK: - CSSGenerator

    @Test("Generates CSS custom properties from tokens")
    func generateCSS() {
        let tokens: [AnyDesignToken] = [
            DesignToken(name: "primary", category: .color, value: ColorValue(hex: "#FF6B35")).erased,
            DesignToken(name: "1", category: .spacing, value: SpacingValue(rem: 0.25)).erased
        ]
        let css = CSSGenerator.generate(from: tokens)
        #expect(css.contains("--ig-color-primary"))
        #expect(css.contains("--ig-space-1"))
        #expect(css.contains(":root"))
    }

    @Test("Empty tokens generates minimal CSS")
    func generateEmptyCSS() {
        let css = CSSGenerator.generate(from: [])
        #expect(css.contains(":root"))
    }

    @Test("Generates media query for dark mode overrides")
    func generateDarkMode() {
        let overrides: [AnyDesignToken] = [
            DesignToken(name: "background", category: .color, value: ColorValue(hex: "#1a1a1a")).erased
        ]
        let css = CSSGenerator.generateDarkMode(from: overrides)
        #expect(css.contains("prefers-color-scheme: dark"))
        #expect(css.contains("--ig-color-background"))
    }
}
