//
// String-HTMLCharacterReferences.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for decoding HTML character references into the characters they name, as the
/// HTML standard's tokenizer does for text.
@Suite("HTML Character Reference Tests")
struct HTMLCharacterReferenceTests {
    @Test("Named references are decoded", arguments: [
        ("&copy; 2026", "\u{A9} 2026"),
        ("Caf&eacute;", "Caf\u{E9}"),
        ("a&nbsp;b", "a\u{A0}b"),
        ("&hellip;&mdash;&ndash;", "\u{2026}\u{2014}\u{2013}"),
        ("&ldquo;quoted&rdquo;", "\u{201C}quoted\u{201D}"),
        ("&AElig;&aelig;", "\u{C6}\u{E6}"),
        ("&amp;&lt;&gt;&quot;&apos;", "&<>\"'"),
        // The longest name in the standard.
        ("&CounterClockwiseContourIntegral;", "\u{2233}"),
        // Names are case-sensitive: these are two different characters.
        ("&Dagger;&dagger;", "\u{2021}\u{2020}"),
        // A reference that stands for two code points.
        ("&NotEqualTilde;", "\u{2242}\u{338}"),
        ("&fjlig;", "fj")
    ])
    func namedReferences(html: String, text: String) {
        #expect(html.plainTextFromHTML() == text)
    }

    @Test("Names the standard allows without a semicolon are decoded without one", arguments: [
        ("&copy 2026", "\u{A9} 2026"),
        ("AT&amp T", "AT& T"),
        ("&ampx;", "&x;"),
        // `&not` is one of them, and the longest match wins: `&notin;` is its own name.
        ("&notit;", "\u{AC}it;"),
        ("&notin;", "\u{2209}"),
        ("&notin", "\u{AC}in")
    ])
    func legacyNamedReferences(html: String, text: String) {
        #expect(html.plainTextFromHTML() == text)
    }

    @Test("Text that is not a reference is left as written", arguments: [
        "&bogus;", "&bogus", "AT&T", "a & b", "&", "&;", "&#;", "&#x;", "&#xZ;", "& amp;", "&hellip",
        "&Copy;", "&#", "100% &"
    ])
    func notReferences(html: String) {
        #expect(html.plainTextFromHTML() == html)
    }

    @Test("Numeric references are decoded", arguments: [
        ("&#65;&#x42;&#X43;", "ABC"),
        ("&#39;&#x27;", "''"),
        ("&#169;", "\u{A9}"),
        ("&#x1F600;", "\u{1F600}"),
        ("&#128512;", "\u{1F600}"),
        ("&#x10FFFD;", "\u{10FFFD}"),
        ("&#0065;", "A"),
        ("&#x000041;", "A"),
        // The semicolon is expected but not required.
        ("&#65 &#x42", "A B"),
        ("&#65B", "AB")
    ])
    func numericReferences(html: String, text: String) {
        #expect(html.plainTextFromHTML() == text)
    }

    @Test("A numeric reference to a code point that cannot be a character becomes U+FFFD", arguments: [
        "&#0;", "&#x0;", "&#xD800;", "&#xDFFF;", "&#55357;", "&#x110000;", "&#1114112;",
        "&#99999999999999999999999999;", "&#xFFFFFFFFFFFFFFFFFFFFFFFF;"
    ])
    func invalidNumericReferences(html: String) {
        #expect(html.plainTextFromHTML() == "\u{FFFD}")
    }

    @Test("A numeric reference in the C1 range is read as Windows-1252, as browsers read it", arguments: [
        ("&#x80;", "\u{20AC}"), ("&#128;", "\u{20AC}"), ("&#x85;", "\u{2026}"), ("&#x92;", "\u{2019}"),
        ("&#x93;&#x94;", "\u{201C}\u{201D}"), ("&#x99;", "\u{2122}"), ("&#x9F;", "\u{178}"),
        // The five the encoding leaves undefined stay as the control they name.
        ("&#x81;", "\u{81}"), ("&#x8D;", "\u{8D}"), ("&#x8F;", "\u{8F}"), ("&#x90;", "\u{90}"),
        ("&#x9D;", "\u{9D}")
    ])
    func windows1252NumericReferences(html: String, text: String) {
        #expect(html.plainTextFromHTML() == text)
    }

    @Test("A decoded reference is not decoded again")
    func decodedOnce() {
        #expect("&amp;copy;".plainTextFromHTML() == "&copy;")
        #expect("&amp;#65;".plainTextFromHTML() == "&#65;")
        #expect("&#38;lt;".plainTextFromHTML() == "&lt;")
    }

    @Test("Tags are removed before references are decoded, so an escaped tag stays text")
    func escapedTagsStayText() {
        #expect("<p>&lt;b&gt;bold&lt;/b&gt; &copy;</p>".plainTextFromHTML() == "<b>bold</b> \u{A9}")
    }

    @Test("A Markdown heading with a named reference gives a title with the character", .publishingContext())
    func markdownTitle() {
        let parser = MarkdownToHTML(markdown: "# Caf&eacute; &copy; 2026\n\nText.", removeTitleFromBody: true)
        #expect(parser.title.plainTextFromHTML() == "Caf\u{E9} \u{A9} 2026")
    }

    // MARK: - The generated table

    @Test("Every line of the generated table is read")
    func tableIsComplete() {
        #expect(HTMLNamedCharacterReferences.count == 2231)
        #expect(HTMLNamedCharacterReferences.parsedCount == 2231)
    }

    @Test("The generated table is in a fixed order, so regenerating it changes only what the standard changed")
    func tableIsSorted() {
        let names = HTMLNamedCharacterReferences.source.split(whereSeparator: \.isNewline).map { line in
            Array(line.prefix { $0 != "=" }.unicodeScalars.map(\.value))
        }
        #expect(names.count == 2231)
        #expect(names == names.sorted { $0.lexicographicallyPrecedes($1) })
    }

    @Test("Every name accepted without a semicolon means the same with one")
    func legacyNamesAgree() {
        var table = [String: String]()
        for line in HTMLNamedCharacterReferences.source.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=")
            table[String(parts[0])] = String(parts[1])
        }

        let legacy = table.keys.filter { $0.hasSuffix(";") == false }.sorted()
        #expect(legacy.count == 106)
        #expect(legacy.map(\.count).max() == HTMLNamedCharacterReferences.longestLegacyNameLength)
        #expect(table.keys.map(\.count).max() == HTMLNamedCharacterReferences.longestNameLength)
        for name in legacy {
            #expect(table[name] == table["\(name);"], "\(name) and \(name); differ")
            #expect("&\(name)".plainTextFromHTML() == "&\(name);".plainTextFromHTML())
        }
    }

    @Test("Every name in the table decodes to its code points")
    func everyNameDecodes() {
        for line in HTMLNamedCharacterReferences.source.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=")
            let expected = parts[1].split(separator: ",")
                .compactMap { UInt32($0, radix: 16).flatMap(Unicode.Scalar.init) }
                .map(String.init).joined()
            #expect(expected.isEmpty == false)
            #expect("&\(parts[0])".plainTextFromHTML() == expected, "&\(parts[0])")
        }
    }
}
