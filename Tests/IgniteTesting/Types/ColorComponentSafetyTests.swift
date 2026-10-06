//
//  ColorComponentSafetyTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for how `Color` converts floating-point components that are not
/// representable as a color component: NaN, infinity and out-of-range values.
@Suite("Color Component Safety Tests")
struct ColorComponentSafetyTests {
    // MARK: - Valid input is unchanged

    @Test("In-range fractional components truncate exactly as before")
    func validComponentsAreUnchanged() {
        #expect(Color(red: 0.5, green: 0.25, blue: 1.0, opacity: 0.5).description == "rgb(127 63 255 / 50%)")
        #expect(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0).description == "rgb(0 0 0 / 0%)")
        #expect(Color(red: 1.0, green: 1.0, blue: 1.0).description == "rgb(255 255 255 / 100%)")
        #expect(Color(red: 0.999, green: 0.001, blue: 0.2).description == "rgb(254 0 51 / 100%)")
    }

    @Test("In-range white values truncate exactly as before")
    func validWhiteIsUnchanged() {
        #expect(Color(white: 0.2).description == "rgb(51 51 51 / 100%)")
        #expect(Color(white: 0.5, opacity: 0.75).description == "rgb(127 127 127 / 75%)")
        #expect(Color(white: 1.0, opacity: 0.0).description == "rgb(255 255 255 / 0%)")
    }

    @Test("An in-range opacity multiplier truncates exactly as before")
    func validOpacityMultiplierIsUnchanged() {
        #expect(Color(red: 255, green: 0, blue: 0).opacity(0.5).description == "rgb(255 0 0 / 50%)")
        #expect(Color(red: 255, green: 0, blue: 0, opacity: 50%).opacity(0.33).description == "rgb(255 0 0 / 16%)")
        #expect(Color(red: 255, green: 0, blue: 0).opacity(0).description == "rgb(255 0 0 / 0%)")
        #expect(Color(red: 255, green: 0, blue: 0).opacity(1).description == "rgb(255 0 0 / 100%)")
    }

    // MARK: - RGB components

    @Test("NaN RGB components become 0 instead of trapping")
    func nanComponents() {
        let color = Color(red: .nan, green: .nan, blue: .nan, opacity: .nan)
        #expect(color.description == "rgb(0 0 0 / 0%)")
    }

    @Test("Infinite RGB components clamp to the end of the range they point at")
    func infiniteComponents() {
        let color = Color(red: .infinity, green: -.infinity, blue: .infinity, opacity: .infinity)
        #expect(color.description == "rgb(255 0 255 / 100%)")
        #expect(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: -Double.infinity).opacity == 0)
    }

    @Test("Finite RGB components too large for Int clamp instead of trapping")
    func hugeComponents() {
        let color = Color(red: 1e300, green: -1e300, blue: 1e300, opacity: 1e300)
        #expect(color.description == "rgb(255 0 255 / 100%)")
    }

    @Test("Finite out-of-range RGB components clamp to 0 through 255")
    func outOfRangeComponents() {
        let color = Color(red: 2.0, green: -1.0, blue: 1.5, opacity: 3.0)
        #expect(color.description == "rgb(255 0 255 / 100%)")
        #expect(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: -0.5).opacity == 0)
    }

    // MARK: - White

    @Test("Unrepresentable white values clamp instead of trapping", arguments: [
        (Double.nan, 0), (Double.infinity, 255), (-Double.infinity, 0), (1e300, 255), (-1e300, 0), (7, 255), (-7, 0)
    ])
    func unrepresentableWhite(white: Double, expected: Int) {
        let color = Color(white: white)
        #expect(color.red == expected)
        #expect(color.green == expected)
        #expect(color.blue == expected)
        #expect(color.opacity == 100)
    }

    @Test("Unrepresentable white opacity clamps instead of trapping", arguments: [
        (Double.nan, 0), (Double.infinity, 100), (-Double.infinity, 0), (1e300, 100), (2, 100), (-2, 0)
    ])
    func unrepresentableWhiteOpacity(opacity: Double, expected: Int) {
        #expect(Color(white: 0.2, opacity: opacity).description == "rgb(51 51 51 / \(expected)%)")
    }

    // MARK: - Opacity multiplier

    @Test("An unrepresentable opacity multiplier clamps instead of trapping", arguments: [
        (Double.nan, 0), (Double.infinity, 100), (-Double.infinity, 0), (1e300, 100), (-1e300, 0), (2, 100), (-1, 0)
    ])
    func unrepresentableOpacityMultiplier(multiplier: Double, expected: Int) {
        let color = Color(red: 10, green: 20, blue: 30).opacity(multiplier)
        #expect(color.description == "rgb(10 20 30 / \(expected)%)")
    }
}
