//
//  URLStaticFallbackTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for what `URL(static:)` does with a literal that is not a URL.
@Suite("URL Static Fallback Tests")
class URLStaticFallbackTests: IgniteTestSuite {
    @Test("A valid literal is parsed as before")
    func validLiteral() async throws {
        #expect(URL(static: "https://www.example.com").absoluteString == "https://www.example.com")
        #expect(URL(static: "/images/dog.jpg").absoluteString == "/images/dog.jpg")
        #expect(URL(static: "mailto:ada@example.com").absoluteString == "mailto:ada@example.com")
    }

    @Test("An unparseable literal becomes the blank placeholder and a build warning", .publishingContext())
    func invalidLiteralInsidePublishingContext() async throws {
        // The empty string is the one input URL(string:) rejects on every Foundation version.
        let url = URL(static: "")

        #expect(url.absoluteString == "about:blank")
        #expect(publishingContext.warnings.contains(
            "A URL was created from a string that is not a valid URL: ''. It was replaced with about:blank."))
    }

    @Test("An unparseable literal does not trap outside a publishing context")
    func invalidLiteralOutsidePublishingContext() async throws {
        #expect(URL(static: "").absoluteString == "about:blank")
    }
}
