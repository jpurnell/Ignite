//
//  TextEscaping.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for which strings are HTML and which are plain text, and that plain text is escaped.
///
/// The rule: a string used as an element – `Text("…")`, a string in a builder – is HTML.
/// A string that is a page title, an attribute, metadata, or data read from an article
/// is plain text, and Ignite escapes it.
@Suite("Text Escaping Tests")
struct TextEscapingTests {
    // MARK: - Strings used as elements are HTML

    @Test("A string used as an element is HTML and is written as given", .publishingContext())
    func stringElementIsMarkup() {
        #expect(Text("Hello <strong>world</strong> &copy; 2024").markupString()
            == "<p>Hello <strong>world</strong> &copy; 2024</p>")
    }

    @Test("Text(verbatim:) shows a string exactly as written", .publishingContext())
    func verbatimTextIsEscaped() {
        #expect(Text(verbatim: "a < b && c > d, said \"x\" &copy;").markupString()
            == "<p>a &lt; b &amp;&amp; c &gt; d, said &quot;x&quot; &amp;copy;</p>")
    }

    @Test("Text(verbatim:) leaves ordinary text alone", .publishingContext())
    func verbatimOrdinaryText() {
        #expect(Text(verbatim: "It's plain text.").markupString() == "<p>It's plain text.</p>")
    }

    // MARK: - Page titles

    @Test("An ordinary page title is written as given", .publishingContext())
    func ordinaryTitle() {
        #expect(Title("It's a page: 100%").markupString() == "<title>It's a page: 100% - My Test Site</title>")
    }

    @Test("A page title is plain text", .publishingContext())
    func titleIsEscaped() {
        #expect(Title("Tom & Jerry </title><script>alert(1)</script>").markupString() == """
        <title>Tom &amp; Jerry &lt;/title&gt;&lt;script&gt;alert(1)&lt;/script&gt; - My Test Site</title>
        """)
    }

    // MARK: - Markdown

    @Test("Markdown without special characters renders as before", .publishingContext())
    func ordinaryMarkdown() {
        let parser = MarkdownToHTML(markdown: "Some *plain* text with <span class=\"x\">inline HTML</span>.",
                                    removeTitleFromBody: false)
        #expect(parser.body == "<p>Some <em>plain</em> text with <span class=\"x\">inline HTML</span>.</p>")
    }

    @Test("Text in Markdown is escaped", .publishingContext())
    func markdownTextIsEscaped() {
        let parser = MarkdownToHTML(markdown: "Tom & Jerry: 1 < 2 > 0", removeTitleFromBody: false)
        #expect(parser.body == "<p>Tom &amp; Jerry: 1 &lt; 2 &gt; 0</p>")
    }

    @Test("A tag written as text in Markdown stays text", .publishingContext(), arguments: [
        "Avoid &lt;script&gt; here",
        #"Avoid \<script\> here"#
    ])
    func markdownEscapedTagStaysText(markdown: String) {
        let parser = MarkdownToHTML(markdown: markdown, removeTitleFromBody: false)
        #expect(parser.body == "<p>Avoid &lt;script&gt; here</p>")
    }

    @Test("A Markdown link's address and an image's description are escaped as attributes", .publishingContext())
    func markdownAttributesAreEscaped() {
        let link = MarkdownToHTML(markdown: "[go](https://example.com/?a=1&b=2)", removeTitleFromBody: false)
        #expect(link.body == "<p><a href=\"https://example.com/?a=1&amp;b=2\">go</a></p>")

        let image = MarkdownToHTML(markdown: "![Tom & <Jerry>](/images/a.png)", removeTitleFromBody: false)
        #expect(image.body == """
        <p><img src="/images/a.png" alt="Tom &amp; &lt;Jerry&gt;" class="img-fluid"></p>
        """)
    }

    @Test("Markdown code has its angle brackets escaped", .publishingContext())
    func markdownCodeIsEscaped() {
        let inline = MarkdownToHTML(markdown: "Use `Array<Int>` when `a && b`", removeTitleFromBody: false)
        #expect(inline.body == "<p>Use <code>Array&lt;Int&gt;</code> when <code>a &amp;&amp; b</code></p>")

        let block = MarkdownToHTML(markdown: "```swift\nlet x: Array<Int> = []\n```", removeTitleFromBody: false)
        #expect(block.body == "<pre><code class=\"language-swift\">let x: Array&lt;Int&gt; = []\n</code></pre>")
    }

    @Test("Markdown code that already uses character references is not escaped twice", .publishingContext())
    func markdownCodeKeepsCharacterReferences() {
        let inline = MarkdownToHTML(markdown: "Use `Array&lt;Int&gt;` or `&amp;` or `&#60;`", removeTitleFromBody: false)
        #expect(inline.body == "<p>Use <code>Array&lt;Int&gt;</code> or <code>&amp;</code> or <code>&#60;</code></p>")
    }

    @Test("A Markdown code block's language cannot end its attribute", .publishingContext())
    func markdownCodeLanguageIsEscaped() {
        let block = MarkdownToHTML(markdown: "```a\"b\ncode\n```", removeTitleFromBody: false)
        #expect(block.body == "<pre><code class=\"language-a&quot;b\">code\n</code></pre>")
    }

    @Test("A Markdown title and description are plain text", .publishingContext())
    func markdownTitleAndDescriptionArePlainText() {
        let parser = MarkdownToHTML(
            markdown: "# Tom & *Jerry* &lt;Live&gt;\n\nA <em>short</em> tale of 1 < 2 & more.",
            removeTitleFromBody: true)

        #expect(parser.title.plainTextFromHTML() == "Tom & Jerry <Live>")
        #expect(parser.description.plainTextFromHTML() == "A short tale of 1 < 2 & more.")
    }

    @Test("Plain text from HTML without tags or references is unchanged")
    func plainTextFromOrdinaryHTML() {
        #expect("Just some text, it's fine.".plainTextFromHTML() == "Just some text, it's fine.")
        #expect("<p>Some <em>text</em></p>".plainTextFromHTML() == "Some text")
        #expect("&amp;lt; &quot;q&quot; &#39;s&#x27; &apos; &copy; &bogus".plainTextFromHTML()
            == "&lt; \"q\" 's' ' &copy; &bogus")
    }

    // MARK: - Code elements

    @Test("Code and CodeBlock escape angle brackets and bare ampersands", .publishingContext())
    func codeIsEscaped() {
        #expect(Code("Array<Int> && x").markupString() == "<code>Array&lt;Int&gt; &amp;&amp; x</code>")
        #expect(CodeBlock { "let a: Array<Int> = b && c" }.markupString()
            == "<pre><code>let a: Array&lt;Int&gt; = b &amp;&amp; c</code></pre>")
    }

    @Test("Code and CodeBlock leave character references as they are", .publishingContext())
    func codeKeepsCharacterReferences() {
        #expect(Code("Array&lt;Int&gt; &amp; \"x\"").markupString() == "<code>Array&lt;Int&gt; &amp; \"x\"</code>")
        #expect(CodeBlock { "Array&lt;Int&gt; &#38; it's" }.markupString()
            == "<pre><code>Array&lt;Int&gt; &#38; it's</code></pre>")
    }

    // MARK: - Article data

    private static func article(title: String, description: String = "", tags: String? = nil) -> Article {
        var article = Article()
        article.title = title
        article.description = description
        article.path = "/story"
        if let tags { article.metadata["tags"] = tags }
        return article
    }

    @Test("A link to an article shows its title as text", .publishingContext())
    func articleLinkEscapesTitle() {
        #expect(Link(Self.article(title: "Plain title")).markupString() == "<a href=\"/story/\">Plain title</a>")
        #expect(Link(Self.article(title: "Tom & Jerry <Live>")).markupString()
            == "<a href=\"/story/\">Tom &amp; Jerry &lt;Live&gt;</a>")
    }

    @Test("An article preview shows the description as text", .publishingContext())
    func articlePreviewEscapesDescription() {
        let preview = ArticlePreview(for: Self.article(title: "T", description: "1 < 2 & <b>bold</b>"))
        #expect(preview.markupString().contains("1 &lt; 2 &amp; &lt;b&gt;bold&lt;/b&gt;</p>"))
    }

    @Test("Tag links show the tag as text", .publishingContext())
    func tagLinksEscapeNames() throws {
        let links = try #require(Self.article(title: "T", tags: "R&D, swift").tagLinks(style: .plain))
        #expect(links.map { $0.markupString() } == [
            "<a rel=\"tag\" href=\"/tags/r-d/\">R&amp;D</a>",
            "<a rel=\"tag\" href=\"/tags/swift/\">swift</a>"
        ])

        let badges = try #require(Self.article(title: "T", tags: "R&D").tagLinks())
        #expect(badges.map { $0.markupString() } == [
            "<a rel=\"tag\" href=\"/tags/r-d/\"><span class=\"badge text-bg-primary rounded-pill\">R&amp;D</span></a>"
        ])
    }

    @Test("A table's accessibility label is plain text", .publishingContext())
    func tableCaptionIsEscaped() {
        let table = Table {}.accessibilityLabel("Sales < costs & </caption><script>")
        #expect(table.markupString().contains("<caption>Sales &lt; costs &amp; &lt;/caption&gt;&lt;script&gt;</caption>"))
    }

    // MARK: - JSON-LD

    @Test("Structured data cannot close its script element", .publishingContext())
    func structuredDataCannotCloseScript() {
        let data = StructuredData.organization(name: "</script><script>alert(1)</script>", url: "https://example.com")
        let output = data.markupString()

        #expect(output.contains("</script><script>") == false)
        #expect(output.contains(#""name" : "\u003C/script>\u003Cscript>alert(1)\u003C/script>""#))
        #expect(output.hasSuffix("\n</script>"))
    }

    @Test("Structured data without angle brackets is written as before", .publishingContext())
    func ordinaryStructuredData() {
        let data = StructuredData.organization(name: "Tom & Jerry's \"Co\"", url: "https://example.com/a")
        #expect(data.markupString().contains(#""name" : "Tom & Jerry's \"Co\"""#))
        #expect(data.markupString().contains(#""url" : "https://example.com/a""#))
    }

    @Test("Hand-written structured data cannot close its script element", .publishingContext())
    func rawStructuredDataCannotCloseScript() {
        let data = StructuredData(json: #"{"name": "</script><b>"}"#)
        #expect(data.markupString() == """
        <script type="application/ld+json">
        {"name": "\\u003C/script>\\u003Cb>"}
        </script>
        """)
    }
}
