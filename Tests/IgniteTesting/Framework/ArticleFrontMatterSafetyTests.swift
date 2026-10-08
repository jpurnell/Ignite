//
//  ArticleFrontMatterSafetyTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that YAML front matter is parsed regardless of the file's line endings.
@Suite("Article Front Matter Safety Tests")
class ArticleFrontMatterSafetyTests: IgniteTestSuite {
    /// Writes Markdown to a temporary file, parses it as an article, and removes the file.
    private func article(fromMarkdown markdown: String) throws -> Article {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "ignite-front-matter-\(UUID().uuidString).md")
        try Data(markdown.utf8).write(to: url)
        defer {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                Issue.record("Could not remove temporary article: \(error)")
            }
        }

        let resourceValues = try url.resourceValues(forKeys: Set(Article.resourceKeys))
        return try Article(
            from: url,
            resourceValues: resourceValues,
            deployPath: "posts/example",
            context: publishingContext
        )
    }

    @Test("Front matter with LF line endings is parsed", .publishingContext())
    func unixLineEndings() async throws {
        let article = try article(fromMarkdown: "---\ntitle: Hello\nauthor: Ada\n---\nBody text")

        #expect(article.metadata["title"] as? String == "Hello")
        #expect(article.metadata["author"] as? String == "Ada")
        #expect(article.title == "Hello")
    }

    @Test("Front matter with CRLF line endings is parsed", .publishingContext())
    func windowsLineEndings() async throws {
        let article = try article(fromMarkdown: "---\r\ntitle: Hello\r\nauthor: Ada\r\n---\r\nBody text")

        #expect(article.metadata["title"] as? String == "Hello")
        #expect(article.metadata["author"] as? String == "Ada")
        // Besides the two front matter entries, Ignite adds the dates and the type itself.
        // No key may carry a stray line ending.
        #expect(article.metadata.keys.sorted() == ["author", "date", "lastModified", "title", "type"])
        #expect(article.title == "Hello")
    }

    @Test("Front matter with classic Mac CR line endings is parsed", .publishingContext())
    func carriageReturnLineEndings() async throws {
        let article = try article(fromMarkdown: "---\rtitle: Hello\rauthor: Ada\r---\rBody text")

        #expect(article.metadata["title"] as? String == "Hello")
        #expect(article.metadata["author"] as? String == "Ada")
    }
}
