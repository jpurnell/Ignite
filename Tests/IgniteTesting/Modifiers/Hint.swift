//
//  Hint.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `Hint` modifier.
@Suite("Hint Tests")
class HintTests: IgniteTestSuite {
    @Test("Markdown Hint", .publishingContext())
    func markdownHint() async throws {
        let element = Text {
            Span("Hover over me")
                .hint(markdown: "Why, *hello* there!")
        }

        let output = element.markupString()

        // The hint's HTML is the value of an attribute, so its angle brackets are written
        // as character references. Bootstrap reads the attribute back as `<em>hello</em>`
        // and, because of `data-bs-html`, shows it as HTML – exactly as before.
        #expect(output == """
        <p><span data-bs-toggle="tooltip" \
        data-bs-title="Why, &lt;em&gt;hello&lt;/em&gt; there!" \
        data-bs-html="true">Hover over me\
        </span>\
        </p>
        """)
    }

    @Test("HMTL Hint", .publishingContext())
    func htmlHint() async throws {
        let element = Text {
            Span("Hover over me")
                .hint(html: "www.example.com")
        }

        let output = element.markupString()

        #expect(output == """
        <p><span data-bs-toggle="tooltip" \
        data-bs-title="www.example.com" \
        data-bs-html="true">Hover over me\
        </span>\
        </p>
        """)
    }

    @Test("HMTL Hint", .publishingContext())
    func textHint() async throws {
        let element = Text {
            Span("Hover over me")
                .hint(text: "Why, hello there!")
        }

        let output = element.markupString()

        #expect(output == """
        <p><span data-bs-toggle="tooltip" \
        data-bs-title="Why, hello there!">Hover over me\
        </span>\
        </p>
        """)
    }
}
