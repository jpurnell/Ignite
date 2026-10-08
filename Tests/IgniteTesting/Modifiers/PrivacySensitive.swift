//
//  PrivacySensitive.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `PrivacySensitive` modifier.
@Suite("PrivacySensitive Tests")
struct PrivacySensitiveTests {
    @Test("Privacy Sensitive Modifier", .publishingContext(),
          arguments: [PrivacyEncoding.urlOnly, PrivacyEncoding.urlAndDisplay])
    func privacySensitive(encoding: PrivacyEncoding) async throws {
        let element = Link("Go Home", target: "/").privacySensitive(encoding)
        let output = element.markupString()

        #expect(output.contains("privacy-sensitive=\"\(encoding.rawValue)\""))
        #expect(output.contains("protected-link"))
    }

    @Test("A privacy-sensitive link is an anchor element", .publishingContext())
    func privacySensitiveLinkIsAnAnchor() async throws {
        let output = Link("Mail me", target: "mailto:me@example.com").privacySensitive().markupString()

        #expect(output == """
        <a privacy-sensitive="urlOnly" href="#" class="protected-link" \
        data-encoded-url="bWFpbHRvOm1lQGV4YW1wbGUuY29t">Mail me</a>
        """)
    }

    @Test("A privacy-sensitive link group is an anchor element", .publishingContext())
    func privacySensitiveLinkGroupIsAnAnchor() async throws {
        let output = LinkGroup(target: "mailto:me@example.com") { Text("Mail me") }
            .customAttribute(name: "privacy-sensitive", value: "urlOnly")
            .markupString()

        #expect(output.hasPrefix("<a privacy-sensitive=\"urlOnly\" href=\"#\" "))
        #expect(output.hasSuffix("><p>Mail me</p></a>"))
    }
}
