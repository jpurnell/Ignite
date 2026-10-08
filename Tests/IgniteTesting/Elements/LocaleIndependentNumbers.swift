//
//  LocaleIndependentNumbers.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A site whose code blocks show line numbers starting from a chosen line.
private struct NumberedLinesSite: Site {
    var name = "Test"
    var url = URL(static: "https://www.example.com")
    var homePage = TestPage()
    var layout = EmptyLayout()
    var syntaxHighlighterConfiguration: SyntaxHighlighterConfiguration

    init(lineNumberVisibility: SyntaxHighlighterConfiguration.LineNumberVisibility) {
        self.syntaxHighlighterConfiguration = SyntaxHighlighterConfiguration(
            languages: [],
            lineNumberVisibility: lineNumberVisibility
        )
    }
}

/// Numbers written into HTML attributes, CSS and JavaScript are read by a parser, not a
/// person, so they must be plain ASCII digits whatever locale the build runs in. A number
/// of 1,000 or more is where grouping separators show up under `en_US`.
@Suite("Locale-independent numbers in markup")
class LocaleIndependentNumbersTests: IgniteTestSuite {
    @Test("Carousel interval of a second or more has no grouping separator", .publishingContext(), arguments: zip(
        [0.5, 1, 5, 12.5, 1000],
        ["500", "1000", "5000", "12500", "1000000"]))
    func carouselInterval(seconds: Double, expected: String) async throws {
        let element = Carousel {
            Slide { Text("One") }
        }
        .slideDuration(seconds)

        let output = element.markupString()
        let attribute = try #require(output.firstMatch(of: #/ data-bs-interval="([^"]*)"/#))

        #expect(attribute.1 == expected)
    }

    @Test("Code block start line has no grouping separator", .publishingContext(), arguments: zip(
        [10, 1000, 1_234_567],
        ["10", "1000", "1234567"]))
    func codeBlockStartLine(firstLine: Int, expected: String) throws {
        let output = try withPublishingContext(for: NumberedLinesSite(lineNumberVisibility: .hidden)) { _ in
            CodeBlock(.swift) { "let x = 1" }
                .lineNumberVisibility(.visible(firstLine: firstLine, linesWrap: false))
                .markupString()
        }

        #expect(output == """
        <pre class="line-numbers" data-start="\(expected)"><code class="language-swift">let x = 1</code></pre>
        """)
    }

    @Test("Code block start line overriding the site's has no grouping separator", .publishingContext(), arguments: zip(
        [5, 2500],
        ["5", "2500"]))
    func codeBlockStartLineOverridingSite(firstLine: Int, expected: String) throws {
        let site = NumberedLinesSite(lineNumberVisibility: .visible(firstLine: 1, linesWrap: false))
        let output = try withPublishingContext(for: site) { _ in
            CodeBlock(.swift) { "let x = 1" }
                .lineNumberVisibility(.visible(firstLine: firstLine, linesWrap: false))
                .markupString()
        }

        #expect(output == """
        <pre data-start="\(expected)"><code class="language-swift">let x = 1</code></pre>
        """)
    }

    @Test("Body start line has no grouping separator", .publishingContext(), arguments: zip(
        [5, 1000],
        ["5", "1000"]))
    func bodyStartLine(firstLine: Int, expected: String) throws {
        let site = NumberedLinesSite(lineNumberVisibility: .visible(firstLine: firstLine, linesWrap: false))
        let output = try withPublishingContext(for: site) { _ in
            Body { Text("TEXT") }.markupString()
        }

        #expect(output == """
        <body class="line-numbers container" data-start="\(expected)"><p>TEXT</p>\
        <script src="/js/bootstrap.bundle.min.js"></script><script src="/js/ignite-core.js"></script></body>
        """)
    }

    @Test("Column span has no grouping separator", .publishingContext(), arguments: zip(
        [1, 12, 1000],
        ["1", "12", "1000"]))
    func columnSpan(span: Int, expected: String) async throws {
        let element = Column { "Cell" }.columnSpan(span)

        #expect(element.markupString() == #"<td colspan="\#(expected)">Cell</td>"#)
    }

    @Test("Line limit has no grouping separator", .publishingContext(), arguments: zip(
        [3, 1000, 20_000],
        ["3", "1000", "20000"]))
    func lineLimit(limit: Int, expected: String) async throws {
        let element = Text("Hello").lineLimit(limit)

        #expect(element.markupString() == """
        <p class="ig-line-clamp" style="--ig-max-line-length: \(expected)">Hello</p>
        """)
    }

    @Test("Line spacing has no grouping separator", .publishingContext(), arguments: zip(
        [1.5, 2, 1000, 1234.5],
        ["1.5", "2", "1000", "1234.5"]))
    func lineSpacing(spacing: Double, expected: String) async throws {
        let element = Text("Hello").lineSpacing(spacing)

        #expect(element.markupString() == #"<p style="line-height: \#(expected)">Hello</p>"#)
    }

    @Test("Font weight is written in plain digits", .publishingContext(), arguments: zip(
        Font.Weight.allCases,
        ["100", "200", "300", "400", "500", "600", "700", "800", "900"]))
    func fontWeight(weight: Font.Weight, expected: String) async throws {
        #expect(weight.description == expected)
        #expect(Text("Hello").fontWeight(weight).markupString() == #"<p style="font-weight: \#(expected)">Hello</p>"#)
        #expect(Span("Hello").fontWeight(weight).markupString()
            == #"<span style="font-weight: \#(expected)">Hello</span>"#)
    }

    @Test("Underline prominence is written in plain digits", .publishingContext(), arguments: zip(
        [0, 10, 25, 50, 75, 100],
        ["0", "10", "25", "50", "75", "100"]))
    func underlineProminence(rawValue: Int, expected: String) async throws {
        let prominence = try #require(UnderlineProminence(rawValue: rawValue))
        #expect(prominence.description == expected)
    }
}
