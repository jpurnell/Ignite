//
//  AspectRatio.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `AspectRatio` modifier.
@Suite("AspectRatio Tests")
class AspectRatioTests: IgniteTestSuite {
    @Test("Verify AspectRatio Modifiers", .publishingContext(), arguments: AspectRatio.allCases)
    func verifyAspectRatioModifiers(ratio: AspectRatio) async throws {
        let element = Text("Hello").aspectRatio(ratio)
        let output = element.markupString()

        #expect(output == "<p class=\"ratio ratio-\(ratio.rawValue)\">Hello</p>")
    }

    @Test("A custom ratio becomes a percentage of the width", .publishingContext())
    func customRatio() async throws {
        let element = Text("Hello").aspectRatio(2)
        let output = element.markupString()

        #expect(output == "<p class=\"ratio\" style=\"--bs-aspect-ratio: 50.0%\">Hello</p>")
    }

    @Test("A custom ratio that isn't positive falls back to square", .publishingContext(), arguments: [0, -2, Double.nan])
    func nonPositiveCustomRatio(ratio: Double) async throws {
        let element = Text("Hello").aspectRatio(ratio)
        let output = element.markupString()

        #expect(output == "<p class=\"ratio\" style=\"--bs-aspect-ratio: 100.0%\">Hello</p>")
    }

    @Test("Verify Content Modes", .publishingContext(), arguments: AspectRatio.allCases, ContentMode.allCases)
    func verifyContentModes(ratio: AspectRatio, mode: ContentMode) async throws {
        let element = Image("/images/example.jpg").aspectRatio(ratio, contentMode: mode)
        let output = element.markupString()

        #expect(output == """
        <div class="ratio ratio-\(ratio.rawValue)">\
        <img src="/images/example.jpg" alt="" class="\(mode.htmlClass)" /></div>
        """)
    }
}
