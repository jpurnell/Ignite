//
//  String-EscapedForHTML.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Testing

@testable import Ignite

/// Tests for `String.escapedForHTML()`, which writes plain text so that HTML reads it back as that text.
@Suite("String-EscapedForHTML Tests")
struct StringEscapedForHTMLTests {
    @Test("Text with nothing to escape is unchanged", arguments: [
        "", "Hello, world", "it's 100% fine: a/b?c=d#e", "naïve café ☕️", "line one\nline two"
    ])
    func ordinaryTextIsUnchanged(text: String) {
        #expect(text.escapedForHTML() == text)
    }

    @Test("The four characters HTML reads as markup are written as character references")
    func markupCharactersAreEscaped() {
        #expect("Tom & Jerry".escapedForHTML() == "Tom &amp; Jerry")
        #expect("a < b".escapedForHTML() == "a &lt; b")
        #expect("a > b".escapedForHTML() == "a &gt; b")
        #expect(#"say "hi""#.escapedForHTML() == "say &quot;hi&quot;")
        #expect(#""><script>alert(1)</script>"#.escapedForHTML()
            == "&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;")
    }

    @Test("A character reference in the text is text, and is escaped like any other")
    func existingReferencesAreEscaped() {
        #expect("&amp;".escapedForHTML() == "&amp;amp;")
        #expect("&lt;b&gt;".escapedForHTML() == "&amp;lt;b&amp;gt;")
    }

    @Test("A single quote is left alone, because Ignite writes every attribute in double quotes")
    func singleQuoteIsUnchanged() {
        #expect("it's".escapedForHTML() == "it's")
    }
}
