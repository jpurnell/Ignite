//
//  String-CSSStringLiteral.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that a name or an address written into CSS as a string cannot end that string.
@Suite("String-CSSStringLiteral Tests")
struct StringCSSStringLiteralTests {
    @Test("Ordinary names and addresses are quoted and otherwise unchanged", arguments: [
        ("Arial", "'Arial'"),
        ("Times New Roman", "'Times New Roman'"),
        ("/images/photo (1).jpg", "'/images/photo (1).jpg'"),
        ("https://example.com/a.png?x=1&y=2", "'https://example.com/a.png?x=1&y=2'"),
        ("", "''")
    ])
    func ordinaryValues(value: String, expected: String) {
        #expect(value.cssStringLiteral() == expected)
    }

    @Test("A quote, a backslash or a line break cannot end the string")
    func hostileValues() {
        #expect("a'b".cssStringLiteral() == #"'a\'b'"#)
        #expect(#"a\b"#.cssStringLiteral() == #"'a\\b'"#)
        #expect("a\nb".cssStringLiteral() == #"'a\a b'"#)
        #expect("a\rb".cssStringLiteral() == #"'a\d b'"#)
        #expect("x'); } body { display: none".cssStringLiteral() == #"'x\'); } body { display: none'"#)
    }

    @Test("A background image address cannot end its url()", .publishingContext())
    func backgroundImage() {
        let plain = Text("x").background(image: "/images/a.png", contentMode: .fill).markupString()
        #expect(plain.contains("background-image: url('/images/a.png');"))

        let hostile = Text("x").background(image: "/a.png'); color: red; x: url('", contentMode: .fill).markupString()
        #expect(hostile.contains(#"background-image: url('/a.png\'); color: red; x: url(\'');"#))
    }

    @Test("A font family cannot end its string", .publishingContext())
    func fontFamily() {
        let plain = Text("x").font(Font(name: "Times New Roman", size: .px(16))).markupString()
        #expect(plain.contains("font-family: 'Times New Roman'"))

        let hostile = Text("x").font(Font(name: "A'; color: red; x: '", size: .px(16))).markupString()
        #expect(hostile.contains(#"font-family: 'A\'; color: red; x: \''"#))
    }

    @Test("A font-face rule's family and source cannot end their strings")
    func fontFace() {
        #expect(FontFaceRule(family: "My Font", source: "/fonts/a.woff2").render().contains("""
            font-family: 'My Font';
            src: url('/fonts/a.woff2');
        """))

        let hostile = FontFaceRule(family: "A'B", source: "/fonts/a'b.woff2").render()
        #expect(hostile.contains(#"font-family: 'A\'B';"#))
        #expect(hostile.contains(#"src: url('/fonts/a\'b.woff2');"#))
    }

    @Test("An import rule's address cannot end its string")
    func importRule() throws {
        let plain = try #require(URL(string: "https://fonts.example.com/css?family=A"))
        #expect(ImportRule(plain).render() == "@import url('https://fonts.example.com/css?family=A');")

        let hostile = try #require(URL(string: "https://fonts.example.com/a'b"))
        #expect(ImportRule(hostile).render() == #"@import url('https://fonts.example.com/a\'b');"#)
    }
}
