//
//  URL-Unwrapped.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `URL-Unwrapped` extension.
@Suite("URL Static Init Tests")
struct URLUnwrappedTests {
    @Test("Creates URL from valid static string", .publishingContext())
    func createsURLFromValidStaticString() async throws {
        // StaticString can't be passed as a test argument, so each case is written out
        // and goes through the static initializer itself.
        #expect(URL(static: "https://example.com").absoluteString == "https://example.com")
        #expect(URL(static: "https://www.github.com/twostraws/Ignite").absoluteString
            == "https://www.github.com/twostraws/Ignite")
        #expect(URL(static: "https://apple.com/path/to/page").absoluteString == "https://apple.com/path/to/page")
        #expect(URL(static: "file:///Users/test/Documents").absoluteString == "file:///Users/test/Documents")
    }

    @Test("Valid static strings produce correct URLs", .publishingContext())
    func validStaticStringsProduceCorrectURLs() async throws {
        let url = URL(static: "https://example.com")
        #expect(url.absoluteString == "https://example.com")
    }

    @Test("Static init with path", .publishingContext())
    func staticInitWithPath() async throws {
        let url = URL(static: "https://example.com/path/to/page")
        #expect(url.host() == "example.com")
    }
}
