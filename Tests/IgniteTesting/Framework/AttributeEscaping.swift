//
//  AttributeEscaping.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that an attribute value cannot end its attribute or change the document around it.
@Suite("Attribute Escaping Tests")
struct AttributeEscapingTests {
    /// A value that ends a double-quoted attribute and opens a script element if written as-is.
    private static let hostile = #"x" onmouseover="alert(1)"><script>a&b</script>"#

    /// `hostile`, as it must be written inside a double-quoted attribute.
    private static let escaped =
        "x&quot; onmouseover=&quot;alert(1)&quot;&gt;&lt;script&gt;a&amp;b&lt;/script&gt;"

    // MARK: - Ordinary values are written as before

    @Test("Ordinary attribute values are written exactly as given", .publishingContext())
    func ordinaryValuesAreUnchanged() {
        let element = Tag("div") {}
            .id("main-content")
            .class("card", "shadow-sm")
            .style(.fontFamily, "'Helvetica Neue', sans-serif")
            .data("bs-toggle", "collapse")
            .aria(.label, "It's a section: 100%")
            .customAttribute(name: "title", value: "Read more / less (2 of 3)")

        #expect(element.markupString() == """
        <div id="main-content" title="Read more / less (2 of 3)" class="card shadow-sm" \
        style="font-family: 'Helvetica Neue', sans-serif" data-bs-toggle="collapse" \
        aria-label="It's a section: 100%"></div>
        """)
    }

    @Test("An address with no ampersand is written exactly as given", .publishingContext())
    func ordinaryAddressIsUnchanged() {
        let element = Link("Go", target: "https://example.com/a/b?page=2#top")
        #expect(element.markupString() == """
        <a href="https://example.com/a/b?page=2#top">Go</a>
        """)
    }

    // MARK: - Each kind of attribute

    @Test("An ID cannot end its attribute", .publishingContext())
    func idIsEscaped() {
        let element = Tag("div") {}.id(Self.hostile)
        #expect(element.markupString() == "<div id=\"\(Self.escaped)\"></div>")
    }

    @Test("A class cannot end its attribute", .publishingContext())
    func classIsEscaped() {
        let element = Tag("div") {}.class(#"a"b"#, "c<d")
        #expect(element.markupString() == #"<div class="a&quot;b c&lt;d"></div>"#)
    }

    @Test("An inline style cannot end its attribute", .publishingContext())
    func styleIsEscaped() {
        let element = Tag("div") {}.style(.fontFamily, #""Helvetica Neue", serif"#)
        #expect(element.markupString() == """
        <div style="font-family: &quot;Helvetica Neue&quot;, serif"></div>
        """)
    }

    @Test("A data attribute cannot end its attribute", .publishingContext())
    func dataIsEscaped() {
        let element = Tag("div") {}.data("note", Self.hostile)
        #expect(element.markupString() == "<div data-note=\"\(Self.escaped)\"></div>")
    }

    @Test("An ARIA attribute cannot end its attribute", .publishingContext())
    func ariaIsEscaped() {
        let element = Tag("div") {}.aria(.label, Self.hostile)
        #expect(element.markupString() == "<div aria-label=\"\(Self.escaped)\"></div>")
    }

    @Test("A custom attribute cannot end its attribute", .publishingContext())
    func customAttributeIsEscaped() {
        let element = Tag("div") {}.customAttribute(name: "title", value: Self.hostile)
        #expect(element.markupString() == "<div title=\"\(Self.escaped)\"></div>")
    }

    @Test("An ampersand in an address is written as a character reference", .publishingContext())
    func addressAmpersandIsEscaped() {
        // `&copy=1` is the case that matters: written as-is, a browser may read `&copy` as ©.
        let element = Link("Go", target: "https://example.com/?a=1&copy=2")
        #expect(element.markupString().contains(#"href="https://example.com/?a=1&amp;copy=2""#))
    }

    @Test("An image description cannot end its attribute", .publishingContext())
    func imageDescriptionIsEscaped() {
        let element = Image("https://example.com/a.png", description: #"The "best" <cat> & dog"#)
        #expect(element.markupString() == """
        <img src="https://example.com/a.png" alt="The &quot;best&quot; &lt;cat&gt; &amp; dog" />
        """)
    }

    @Test("Metadata content cannot end its attribute", .publishingContext())
    func metaContentIsEscaped() {
        let element = MetaTag(.openGraphTitle, content: #"Tom & Jerry: "The <Movie>""#)
        #expect(element.markupString() == """
        <meta property="og:title" content="Tom &amp; Jerry: &quot;The &lt;Movie&gt;&quot;" />
        """)
    }

    @Test("A value that already holds a character reference is not treated as markup", .publishingContext())
    func characterReferenceIsWrittenAsText() {
        // The value is the text `&quot;`, so that is what a browser must read back.
        let element = Tag("div") {}.customAttribute(name: "title", value: "&quot;")
        #expect(element.markupString() == #"<div title="&amp;quot;"></div>"#)
    }

    // MARK: - Events

    @Test("Generated JavaScript is written into an event attribute unchanged", .publishingContext())
    func generatedEventIsUnchanged() {
        let element = Tag("div") {}.onClick { ShowElement(#"a"b&c<d"#) }
        #expect(element.markupString() == #"""
        <div onclick="document.getElementById('a\u0022b\u0026c\u003Cd').classList.remove('d-none')"></div>
        """#)
    }

    @Test("Hand-written JavaScript is read back by the browser as it was written", .publishingContext())
    func handWrittenEventIsEscapedOnce() {
        let element = Tag("div") {}.onClick { CustomAction(#"if (a && b < c) { say("&quot;") }"#) }
        #expect(element.markupString() == """
        <div onclick="if (a &amp;&amp; b &lt; c) { say(&quot;&amp;quot;&quot;) }"></div>
        """)
    }

    // MARK: - Attribute names

    @Test("An attribute name cannot hold the characters that end a name", .publishingContext())
    func attributeNameIsReducedToNameCharacters() {
        let element = Tag("div") {}.customAttribute(name: #"x onclick="alert(1)""#, value: "y")
        #expect(element.markupString() == #"<div xonclickalert(1)="y"></div>"#)
    }

    // MARK: - Elements that write their own tags

    @Test("A table filter's placeholder cannot end its attribute", .publishingContext())
    func tableFilterPlaceholderIsEscaped() {
        let table = Table(filterTitle: #"Find "it" <now>"#) { Row { Column { "x" } } }
        #expect(table.markupString().contains(#"placeholder="Find &quot;it&quot; &lt;now&gt;""#))
    }

    @Test("An audio source cannot end its attribute", .publishingContext())
    func audioSourceIsEscaped() {
        let element = Audio(#"/audio/a"b&c.mp3"#)
        #expect(element.markupString().contains(#"<source src="/audio/a&quot;b&amp;c.mp3" type="audio/mpeg">"#))
    }

    @Test("A video source cannot end its attribute", .publishingContext())
    func videoSourceIsEscaped() {
        let element = Video(#"/video/a"b&c.mp4"#)
        #expect(element.markupString().contains(#"<source src="/video/a&quot;b&amp;c.mp4" type="video/mp4" />"#))
    }

    @Test("An embed's title cannot end its attribute", .publishingContext())
    func embedTitleIsEscaped() throws {
        let url = try #require(URL(string: "https://example.com/embed?a=1&b=2"))
        let element = Embed(title: #"A "great" <video>"#, url: url).aspectRatio(.r16x9)
        let output = element.markupString()
        #expect(output.contains(#"src="https://example.com/embed?a=1&amp;b=2""#))
        #expect(output.contains(#"title="A &quot;great&quot; &lt;video&gt;""#))
    }

    @Test("A default link target cannot end its attribute", .publishingContext())
    func baseTargetIsEscaped() {
        let head = Head {}.standardHeadersDisabled().defaultLinkTarget(.custom(#"a"b"#))
        #expect(head.markupString() == #"<head><base target="a&quot;b" /></head>"#)
    }

    @Test("A button's icon name cannot end its class attribute", .publishingContext())
    func buttonIconIsEscaped() {
        #expect(Button("Go", systemImage: "arrow-right").markupString()
            == #"<button type="button" class="btn"><i class="bi bi-arrow-right" aria-hidden="true"></i> Go</button>"#)
        #expect(Button("Go", systemImage: #"x"><script>"#).markupString()
            == #"<button type="button" class="btn"><i class="bi bi-x&quot;&gt;&lt;script&gt;" aria-hidden="true"></i> Go</button>"#)
    }

    @Test("A tag name is reduced to the characters a name can hold", .publishingContext())
    func tagNameIsReducedToNameCharacters() {
        #expect(Tag("my-element") {}.markupString() == "<my-element></my-element>")
        #expect(Tag("div onclick=\"x\"><script") {}.markupString() == "<divonclickxscript></divonclickxscript>")
    }
}
