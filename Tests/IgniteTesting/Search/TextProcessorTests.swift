//
//  TextProcessorTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `TextProcessor` search utility.
@Suite("TextProcessor Tests")
struct TextProcessorTests {

    // MARK: - stripHTML

    @Test("Strips simple HTML tags")
    func stripSimpleTags() {
        let result = TextProcessor.stripHTML("<p>Hello <b>world</b></p>")
        #expect(result == "Hello world")
    }

    @Test("Strips self-closing tags")
    func stripSelfClosing() {
        let result = TextProcessor.stripHTML("Line one<br/>Line two")
        #expect(result == "Line one Line two")
    }

    @Test("Strips HTML entities")
    func stripEntities() {
        let result = TextProcessor.stripHTML("Tom &amp; Jerry &mdash; friends")
        #expect(result == "Tom Jerry friends")
    }

    @Test("Collapses multiple whitespace")
    func collapseWhitespace() {
        let result = TextProcessor.stripHTML("<p>  hello   world  </p>")
        #expect(result == "hello world")
    }

    @Test("Empty string returns empty")
    func stripEmpty() {
        #expect(TextProcessor.stripHTML("").isEmpty)
    }

    @Test("Plain text passes through unchanged")
    func stripPlainText() {
        #expect(TextProcessor.stripHTML("no tags here") == "no tags here")
    }

    // MARK: - excerpt

    @Test("Short text returns unchanged")
    func excerptShort() {
        let text = "Hello world"
        #expect(TextProcessor.excerpt(from: text, length: 100) == "Hello world")
    }

    @Test("Long text truncates at word boundary with ellipsis")
    func excerptTruncates() {
        let text = "The quick brown fox jumps over the lazy dog"
        let result = TextProcessor.excerpt(from: text, length: 20)
        #expect(result.hasSuffix("..."))
        #expect(result.count <= 23)
    }

    @Test("Empty text returns empty")
    func excerptEmpty() {
        #expect(TextProcessor.excerpt(from: "", length: 100).isEmpty)
    }

    @Test("Excerpt respects word boundary")
    func excerptWordBoundary() {
        let text = "Swift programming language"
        let result = TextProcessor.excerpt(from: text, length: 10)
        #expect(result == "Swift...")
    }

    // MARK: - tokenize

    @Test("Tokenizes text into lowercase words")
    func tokenizeBasic() {
        let tokens = TextProcessor.tokenize("Hello World Swift", language: .english, stem: false, removeStopWords: false)
        #expect(tokens.contains("hello"))
        #expect(tokens.contains("world"))
        #expect(tokens.contains("swift"))
    }

    @Test("Removes stop words when enabled")
    func tokenizeRemovesStopWords() {
        let tokens = TextProcessor.tokenize(
            "the quick brown fox is a test",
            language: .english, stem: false, removeStopWords: true
        )
        #expect(!tokens.contains("the"))
        #expect(!tokens.contains("is"))
        #expect(!tokens.contains("a"))
        #expect(tokens.contains("quick"))
        #expect(tokens.contains("brown"))
    }

    @Test("Deduplicates tokens")
    func tokenizeDeduplicates() {
        let tokens = TextProcessor.tokenize("swift swift swift", language: .english, stem: false, removeStopWords: false)
        #expect(tokens.count == 1)
        #expect(tokens.first == "swift")
    }

    @Test("Splits on non-alphanumeric characters")
    func tokenizeSplitsOnPunctuation() {
        let tokens = TextProcessor.tokenize("hello-world foo_bar", language: .english, stem: false, removeStopWords: false)
        #expect(tokens.contains("hello"))
        #expect(tokens.contains("world"))
        #expect(tokens.contains("foo"))
        #expect(tokens.contains("bar"))
    }

    @Test("Empty text returns empty tokens")
    func tokenizeEmpty() {
        let tokens = TextProcessor.tokenize("", language: .english, stem: false, removeStopWords: false)
        #expect(tokens.isEmpty)
    }

    // MARK: - stemWord

    @Test("Stems common English suffixes")
    func stemCommon() {
        #expect(TextProcessor.stemWord("running", language: .english) == "runn")
        #expect(TextProcessor.stemWord("quickly", language: .english) == "quick")
    }

    @Test("Short words are not stemmed")
    func stemShortWords() {
        #expect(TextProcessor.stemWord("the", language: .english) == "the")
        #expect(TextProcessor.stemWord("is", language: .english) == "is")
    }

    @Test("Stems ational to ate")
    func stemAtional() {
        #expect(TextProcessor.stemWord("informational", language: .english) == "informate")
    }

    @Test("Non-English words pass through unchanged")
    func stemNonEnglish() {
        #expect(TextProcessor.stemWord("running", language: .spanish) == "running")
    }
}
