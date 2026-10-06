//
//  CodeBlockMissingThemeTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A site whose themes provide no syntax highlighter theme at all.
private struct ThemelessSite: Site {
    var name = "Themeless"
    var url = URL(static: "https://www.example.com")
    var homePage = TestSubsitePage()
    var layout = EmptyLayout()
    var lightTheme: (any Theme)? { nil }
    var darkTheme: (any Theme)? { nil }
}

/// Tests for what `CodeBlock` does on a site with no syntax highlighter theme.
@Suite("CodeBlock Missing Theme Tests")
class CodeBlockMissingThemeTests: IgniteTestSuite {
    @Test("A code block on a site with no highlighter theme renders and records one error")
    func missingHighlighterThemeIsRecorded() async throws {
        let (first, second, errors) = try withPublishingContext(for: ThemelessSite()) { context in
            let first = CodeBlock(.swift) { "let a = 1" }.markupString()
            let second = CodeBlock { "plain" }.markupString()
            return (first, second, context.errors.compactMap(\.errorDescription))
        }

        #expect(first == #"<pre><code class="language-swift">let a = 1</code></pre>"#)
        #expect(second == "<pre><code>plain</code></pre>")
        // Two code blocks, but the site is missing one thing, so it is reported once.
        #expect(errors == ["At least one of your themes must specify a syntax highlighter."])
    }

    @Test("A code block on a site with a highlighter theme records no error", .publishingContext())
    func presentHighlighterThemeRecordsNothing() async throws {
        let output = CodeBlock(.swift) { "let a = 1" }.markupString()

        #expect(output == #"<pre><code class="language-swift">let a = 1</code></pre>"#)
        #expect(publishingContext.errors.isEmpty)
    }
}
