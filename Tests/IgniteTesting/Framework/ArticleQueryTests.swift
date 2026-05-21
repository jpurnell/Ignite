//
//  ArticleQueryTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `ArticleQuery` chainable builder.
@Suite("ArticleQuery Tests")
struct ArticleQueryTests {

    // MARK: - Test data

    static func makeArticle(
        title: String,
        tags: String? = nil,
        author: String? = nil,
        published: String? = nil,
        date: Date = .now
    ) -> Article {
        var article = Article()
        article.title = title
        if let tags { article.metadata["tags"] = tags }
        if let author { article.metadata["author"] = author }
        if let published { article.metadata["published"] = published }
        article.metadata["date"] = date
        return article
    }

    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "y-M-d"
        f.timeZone = .gmt
        return f
    }()

    static func date(_ string: String) -> Date {
        formatter.date(from: string) ?? .now
    }

    let articles = [
        makeArticle(title: "Swift Tips", tags: "swift, tips", author: "Alice", date: date("2026-01-15")),
        makeArticle(title: "Ignite Guide", tags: "swift, ignite", author: "Bob", date: date("2026-02-10")),
        makeArticle(title: "Web Basics", tags: "web, html", author: "Alice", date: date("2026-03-05")),
        makeArticle(title: "Draft Post", tags: "swift", published: "false", date: date("2026-04-01")),
        makeArticle(title: "Old Post", tags: "misc", author: "Charlie", date: date("2025-06-01"))
    ]

    // MARK: - Basic query

    @Test("Query all returns all articles", .publishingContext())
    func queryAll() async throws {
        let result = ArticleQuery(articles).all
        #expect(result.count == 5)
    }

    @Test("Query count returns correct count", .publishingContext())
    func queryCount() async throws {
        #expect(ArticleQuery(articles).count == 5)
    }

    @Test("Query first returns first article", .publishingContext())
    func queryFirst() async throws {
        let first = ArticleQuery(articles).first
        #expect(first?.title == "Swift Tips")
    }

    @Test("Empty source returns empty results", .publishingContext())
    func emptySource() async throws {
        #expect(ArticleQuery([Article]()).all.isEmpty)
        #expect(ArticleQuery([Article]()).first == nil)
        #expect(ArticleQuery([Article]()).count == 0)
    }

    // MARK: - Tag filtering

    @Test("Filter by single tag", .publishingContext())
    func taggedSingle() async throws {
        let result = ArticleQuery(articles).tagged("swift").all
        #expect(result.count == 3)
    }

    @Test("Filter by tag excludes non-matching", .publishingContext())
    func taggedExcludes() async throws {
        let result = ArticleQuery(articles).tagged("html").all
        #expect(result.count == 1)
        #expect(result.first?.title == "Web Basics")
    }

    @Test("Filter by any of multiple tags", .publishingContext())
    func taggedAnyOf() async throws {
        let result = ArticleQuery(articles).tagged(anyOf: ["ignite", "html"]).all
        #expect(result.count == 2)
    }

    @Test("Filter by all of multiple tags", .publishingContext())
    func taggedAllOf() async throws {
        let result = ArticleQuery(articles).tagged(allOf: ["swift", "tips"]).all
        #expect(result.count == 1)
        #expect(result.first?.title == "Swift Tips")
    }

    // MARK: - Author filtering

    @Test("Filter by author", .publishingContext())
    func byAuthor() async throws {
        let result = ArticleQuery(articles).by(author: "Alice").all
        #expect(result.count == 2)
    }

    @Test("Filter by non-existent author returns empty", .publishingContext())
    func byAuthorEmpty() async throws {
        let result = ArticleQuery(articles).by(author: "Nobody").all
        #expect(result.isEmpty)
    }

    // MARK: - Published filtering

    @Test("Published filter excludes unpublished", .publishingContext())
    func publishedFilter() async throws {
        let result = ArticleQuery(articles).published().all
        #expect(result.count == 4)
        #expect(!result.contains(where: { $0.title == "Draft Post" }))
    }

    // MARK: - Date filtering

    @Test("After date filter", .publishingContext())
    func afterDate() async throws {
        let result = ArticleQuery(articles).after(Self.date("2026-02-01")).all
        #expect(result.count == 3)
    }

    @Test("Before date filter", .publishingContext())
    func beforeDate() async throws {
        let result = ArticleQuery(articles).before(Self.date("2026-02-01")).all
        #expect(result.count == 2)
    }

    @Test("Between dates filter", .publishingContext())
    func betweenDates() async throws {
        let result = ArticleQuery(articles)
            .between(Self.date("2026-01-01"), and: Self.date("2026-03-01"))
            .all
        #expect(result.count == 2)
    }

    // MARK: - Custom predicate

    @Test("Custom filter predicate", .publishingContext())
    func customFilter() async throws {
        let result = ArticleQuery(articles)
            .filter { $0.title.contains("Post") }
            .all
        #expect(result.count == 2)
    }

    // MARK: - Metadata filtering

    @Test("Metadata key-value filter", .publishingContext())
    func metadataFilter() async throws {
        let result = ArticleQuery(articles).metadata("author", equals: "Bob").all
        #expect(result.count == 1)
        #expect(result.first?.title == "Ignite Guide")
    }

    // MARK: - Sorting

    @Test("Sort by date descending", .publishingContext())
    func sortByDateDesc() async throws {
        let result = ArticleQuery(articles).sorted(by: .date, order: .reverse).all
        #expect(result.first?.title == "Draft Post")
        #expect(result.last?.title == "Old Post")
    }

    @Test("Sort by date ascending", .publishingContext())
    func sortByDateAsc() async throws {
        let result = ArticleQuery(articles).sorted(by: .date, order: .forward).all
        #expect(result.first?.title == "Old Post")
        #expect(result.last?.title == "Draft Post")
    }

    @Test("Sort by title ascending", .publishingContext())
    func sortByTitle() async throws {
        let result = ArticleQuery(articles).sorted(by: .title, order: .forward).all
        #expect(result.first?.title == "Draft Post")
        #expect(result.last?.title == "Web Basics")
    }

    // MARK: - Limit and offset

    @Test("Limit restricts result count", .publishingContext())
    func limit() async throws {
        let result = ArticleQuery(articles).limit(2).all
        #expect(result.count == 2)
    }

    @Test("Offset skips first N results", .publishingContext())
    func offset() async throws {
        let result = ArticleQuery(articles).offset(3).all
        #expect(result.count == 2)
    }

    @Test("Page returns correct slice", .publishingContext())
    func page() async throws {
        let result = ArticleQuery(articles).page(2, size: 2).all
        #expect(result.count == 2)
        #expect(result.first?.title == "Web Basics")
    }

    @Test("totalCount ignores limit/offset", .publishingContext())
    func totalCount() async throws {
        let query = ArticleQuery(articles).tagged("swift").limit(1)
        #expect(query.count == 1)
        #expect(query.totalCount == 3)
    }

    // MARK: - Chaining

    @Test("Multiple filters chain together", .publishingContext())
    func chainingFilters() async throws {
        let result = ArticleQuery(articles)
            .tagged("swift")
            .published()
            .sorted(by: .date, order: .reverse)
            .limit(2)
            .all
        #expect(result.count == 2)
        #expect(result.first?.title == "Ignite Guide")
    }
}
