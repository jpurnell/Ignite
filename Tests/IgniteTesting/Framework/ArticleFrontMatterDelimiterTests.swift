//
//  ArticleFrontMatterDelimiterTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that front matter delimiters with nothing after them do not trap.
@Suite("Article Front Matter Delimiter Tests")
class ArticleFrontMatterDelimiterTests: IgniteTestSuite {
    /// Writes Markdown to a temporary file, parses it as an article, and removes the file.
    private func article(fromMarkdown markdown: String) throws -> Article {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "ignite-delimiter-\(UUID().uuidString).md")
        try Data(markdown.utf8).write(to: url)
        defer {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                Issue.record("Could not remove temporary article: \(error)")
            }
        }

        let resourceValues = try url.resourceValues(forKeys: Set(Article.resourceKeys))
        return try Article(from: url, resourceValues: resourceValues, deployPath: "posts/example")
    }

    @Test("Front matter followed by a body is parsed as before", .publishingContext())
    func frontMatterWithBody() async throws {
        let article = try article(fromMarkdown: "---\ntitle: Hello\n---\nBody --- with a rule")

        #expect(article.metadata["title"] as? String == "Hello")
        #expect(article.text == "<p>Body — with a rule</p>")
    }

    @Test("Closed front matter with no body gives metadata and an empty body", .publishingContext())
    func closedFrontMatterWithoutBody() async throws {
        let article = try article(fromMarkdown: "---\ntitle: Hello\nauthor: Ada\n---")

        #expect(article.metadata["title"] as? String == "Hello")
        #expect(article.metadata["author"] as? String == "Ada")
        #expect(article.text == "")
    }

    @Test("Closed front matter followed only by a newline gives an empty body", .publishingContext())
    func closedFrontMatterWithTrailingNewline() async throws {
        let article = try article(fromMarkdown: "---\ntitle: Hello\n---\n")

        #expect(article.metadata["title"] as? String == "Hello")
        #expect(article.text == "")
    }

    @Test("A file that is only an opening delimiter has no front matter", .publishingContext())
    func onlyOpeningDelimiter() async throws {
        let article = try article(fromMarkdown: "---")

        // With no closing delimiter this is Markdown, where `---` is a thematic break.
        #expect(article.metadata.keys.sorted() == ["date", "lastModified", "type"])
        #expect(article.text == "<hr />")
    }

    @Test("An opening delimiter and a newline has no front matter", .publishingContext())
    func openingDelimiterAndNewline() async throws {
        let article = try article(fromMarkdown: "---\n")

        #expect(article.metadata.keys.sorted() == ["date", "lastModified", "type"])
        #expect(article.text == "<hr />")
    }

    @Test("Front matter that is never closed is not treated as front matter", .publishingContext())
    func unterminatedFrontMatter() async throws {
        let article = try article(fromMarkdown: "---\ntitle: Hello\n\nBody text")

        #expect(article.metadata["title"] == nil)
        #expect(article.metadata.keys.sorted() == ["date", "lastModified", "type"])
        #expect(article.text.contains("Body text"))
    }

    @Test("Two delimiters with nothing between or after them have no metadata and no body", .publishingContext())
    func emptyFrontMatter() async throws {
        let article = try article(fromMarkdown: "---\n---")

        #expect(article.metadata.keys.sorted() == ["date", "lastModified", "type"])
        #expect(article.text == "")
    }
}
