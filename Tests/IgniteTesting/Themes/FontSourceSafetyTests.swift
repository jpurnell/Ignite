//
//  FontSourceSafetyTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for how `Font(name:source:)` handles a source string that is not a URL.
@Suite("Font Source Safety Tests")
class FontSourceSafetyTests: IgniteTestSuite {
    @Test("A valid source string becomes a single font source", .publishingContext())
    func validSourceIsKept() async throws {
        let font = Font(name: "Valkyrie", source: "/fonts/valkyrie_a_regular.woff2")

        #expect(font.name == "Valkyrie")
        #expect(font.sources.map(\.url.absoluteString) == ["/fonts/valkyrie_a_regular.woff2"])
        #expect(publishingContext.warnings.isEmpty)
    }

    @Test("An unparseable source string yields a font with no sources and a warning", .publishingContext())
    func invalidSourceIsDroppedWithWarning() async throws {
        // The empty string is the one input URL(string:) rejects on every Foundation version.
        let font = Font(name: "Valkyrie", source: "")

        #expect(font.name == "Valkyrie")
        #expect(font.sources == [])
        #expect(publishingContext.warnings.contains(
            "The font 'Valkyrie' uses an invalid source URL: ''. It will be used without a font file."))
    }

    @Test("An unparseable source string does not trap outside a publishing context")
    func invalidSourceOutsidePublishingContext() async throws {
        let font = Font(name: "Valkyrie", source: "")

        #expect(font.sources == [])
    }
}
