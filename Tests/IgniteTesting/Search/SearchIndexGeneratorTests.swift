//
//  SearchIndexGeneratorTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `SearchIndexGenerator`.
@Suite("SearchIndexGenerator Tests")
struct SearchIndexGeneratorTests {

    static func makeArticle(
        title: String,
        description: String = "",
        path: String = "blog/test",
        tags: String? = nil,
        author: String? = nil,
        text: String = "",
        published: String? = nil,
        type: String = "blog"
    ) -> Article {
        var article = Article()
        article.title = title
        article.description = description
        article.path = path
        article.text = text
        if let tags { article.metadata["tags"] = tags }
        if let author { article.metadata["author"] = author }
        if let published { article.metadata["published"] = published }
        article.metadata["type"] = type
        return article
    }

    let sampleArticles = [
        makeArticle(
            title: "Swift Tips",
            description: "Helpful Swift tips",
            path: "blog/swift-tips",
            tags: "swift, tips",
            author: "Alice",
            text: "<p>Learn <strong>Swift</strong> programming.</p>"
        ),
        makeArticle(
            title: "Web Guide",
            description: "Building for the web",
            path: "blog/web-guide",
            tags: "web, html",
            author: "Bob",
            text: "<p>HTML and CSS basics.</p>"
        ),
        makeArticle(
            title: "Draft Post",
            path: "blog/draft",
            published: "false"
        )
    ]

    // MARK: - Basic generation

    @Test("Generates entries for published articles only")
    func generatesPublishedOnly() throws {
        let generator = SearchIndexGenerator(
            configuration: .default,
            articles: sampleArticles
        )
        let json = try generator.generateIndex()
        let entries = try JSONDecoder().decode([SearchEntry].self, from: Data(json.utf8))

        #expect(entries.count == 2)
        #expect(!entries.contains { $0.title == "Draft Post" })
    }

    @Test("Disabled configuration returns empty string")
    func disabledReturnsEmpty() throws {
        let generator = SearchIndexGenerator(
            configuration: .disabled,
            articles: sampleArticles
        )
        #expect(try generator.generateIndex().isEmpty)
    }

    @Test("Entry fields are populated correctly")
    func entryFields() throws {
        let generator = SearchIndexGenerator(
            configuration: .default,
            articles: sampleArticles
        )
        let json = try generator.generateIndex()
        let entries = try JSONDecoder().decode([SearchEntry].self, from: Data(json.utf8))
        let swiftEntry = try #require(entries.first { $0.title == "Swift Tips" })

        #expect(swiftEntry.description == "Helpful Swift tips")
        #expect(swiftEntry.url == "/blog/swift-tips")
        #expect(swiftEntry.author == "Alice")
        #expect(swiftEntry.tags == ["swift", "tips"])
    }

    @Test("Tokens include stemmed content")
    func tokensAreStemmed() throws {
        let generator = SearchIndexGenerator(
            configuration: .default,
            articles: sampleArticles
        )
        let json = try generator.generateIndex()
        let entries = try JSONDecoder().decode([SearchEntry].self, from: Data(json.utf8))
        let swiftEntry = try #require(entries.first { $0.title == "Swift Tips" })

        #expect(swiftEntry.tokens.contains("swift"))
    }

    @Test("Excerpt strips HTML")
    func excerptStripsHTML() throws {
        let generator = SearchIndexGenerator(
            configuration: .default,
            articles: sampleArticles
        )
        let json = try generator.generateIndex()
        let entries = try JSONDecoder().decode([SearchEntry].self, from: Data(json.utf8))
        let swiftEntry = try #require(entries.first { $0.title == "Swift Tips" })

        #expect(!swiftEntry.excerpt.contains("<"))
        #expect(!swiftEntry.excerpt.contains(">"))
    }

    // MARK: - Content type filtering

    @Test("Filters by content type when configured")
    func contentTypeFilter() throws {
        let articles = [
            Self.makeArticle(title: "Blog Post", path: "blog/post", type: "blog"),
            Self.makeArticle(title: "Story", path: "stories/story", type: "stories")
        ]

        var config = SearchConfiguration.default
        config.contentTypes = ["blog"]

        let generator = SearchIndexGenerator(configuration: config, articles: articles)
        let json = try generator.generateIndex()
        let entries = try JSONDecoder().decode([SearchEntry].self, from: Data(json.utf8))

        #expect(entries.count == 1)
        #expect(entries.first?.title == "Blog Post")
    }

    @Test("Nil content types includes all articles")
    func nilContentTypesIncludesAll() throws {
        let articles = [
            Self.makeArticle(title: "Blog Post", type: "blog"),
            Self.makeArticle(title: "Story", type: "stories")
        ]

        var config = SearchConfiguration.default
        config.contentTypes = nil

        let generator = SearchIndexGenerator(configuration: config, articles: articles)
        let json = try generator.generateIndex()
        let entries = try JSONDecoder().decode([SearchEntry].self, from: Data(json.utf8))

        #expect(entries.count == 2)
    }

    // MARK: - No stemming

    @Test("Tokens are unstemmed when stemming is disabled")
    func noStemming() throws {
        var config = SearchConfiguration.default
        config.enableStemming = false

        let articles = [Self.makeArticle(title: "Running quickly")]
        let generator = SearchIndexGenerator(configuration: config, articles: articles)
        let json = try generator.generateIndex()
        let entries = try JSONDecoder().decode([SearchEntry].self, from: Data(json.utf8))
        let entry = try #require(entries.first)

        #expect(entry.tokens.contains("running"))
        #expect(entry.tokens.contains("quickly"))
    }

    // MARK: - Empty input

    @Test("Empty article list produces empty index")
    func emptyArticles() throws {
        let generator = SearchIndexGenerator(
            configuration: .default,
            articles: []
        )
        let json = try generator.generateIndex()
        let entries = try JSONDecoder().decode([SearchEntry].self, from: Data(json.utf8))
        #expect(entries.isEmpty)
    }
}
