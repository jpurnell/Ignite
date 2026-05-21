//
//  ArticleQuery.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// A sort field for ordering articles.
public enum ArticleSortField: Sendable {
    case date
    case title
}

/// A chainable query builder for filtering, sorting, and paginating articles.
public struct ArticleQuery: Sendable {
    private let source: [Article]
    private let filters: [ArticleFilter]
    private let sortField: ArticleSortField?
    private let sortOrder: SortOrder
    private let limitCount: Int?
    private let offsetCount: Int?

    /// Creates a query over the given articles.
    public init(_ articles: [Article]) {
        self.source = articles
        self.filters = []
        self.sortField = nil
        self.sortOrder = .forward
        self.limitCount = nil
        self.offsetCount = nil
    }

    private init(
        source: [Article],
        filters: [ArticleFilter],
        sortField: ArticleSortField?,
        sortOrder: SortOrder,
        limitCount: Int?,
        offsetCount: Int?
    ) {
        self.source = source
        self.filters = filters
        self.sortField = sortField
        self.sortOrder = sortOrder
        self.limitCount = limitCount
        self.offsetCount = offsetCount
    }

    // MARK: - Tag filtering

    /// Filters to articles containing the given tag.
    public func tagged(_ tag: String) -> ArticleQuery {
        adding(.tagged(tag))
    }

    /// Filters to articles containing any of the given tags.
    public func tagged(anyOf tags: [String]) -> ArticleQuery {
        adding(.taggedAnyOf(tags))
    }

    /// Filters to articles containing all of the given tags.
    public func tagged(allOf tags: [String]) -> ArticleQuery {
        adding(.taggedAllOf(tags))
    }

    // MARK: - Author filtering

    /// Filters to articles by the given author.
    public func by(author: String) -> ArticleQuery {
        adding(.author(author))
    }

    // MARK: - Published filtering

    /// Filters to articles where `isPublished` is true.
    public func published() -> ArticleQuery {
        adding(.published)
    }

    // MARK: - Date filtering

    /// Filters to articles with a date after the given date.
    public func after(_ date: Date) -> ArticleQuery {
        adding(.after(date))
    }

    /// Filters to articles with a date before the given date.
    public func before(_ date: Date) -> ArticleQuery {
        adding(.before(date))
    }

    /// Filters to articles with a date between the given dates (inclusive start, exclusive end).
    public func between(_ start: Date, and end: Date) -> ArticleQuery {
        adding(.between(start, end))
    }

    // MARK: - Custom filtering

    /// Filters articles using a custom predicate.
    public func filter(_ predicate: @escaping @Sendable (Article) -> Bool) -> ArticleQuery {
        adding(.custom(predicate))
    }

    /// Filters to articles where a metadata key matches the given value.
    public func metadata(_ key: String, equals value: String) -> ArticleQuery {
        adding(.metadata(key, value))
    }

    // MARK: - Sorting

    /// Sorts results by the given field and order.
    public func sorted(by field: ArticleSortField, order: SortOrder = .forward) -> ArticleQuery {
        ArticleQuery(
            source: source, filters: filters,
            sortField: field, sortOrder: order,
            limitCount: limitCount, offsetCount: offsetCount
        )
    }

    // MARK: - Pagination

    /// Limits the number of results returned.
    public func limit(_ count: Int) -> ArticleQuery {
        ArticleQuery(
            source: source, filters: filters,
            sortField: sortField, sortOrder: sortOrder,
            limitCount: count, offsetCount: offsetCount
        )
    }

    /// Skips the first N results.
    public func offset(_ count: Int) -> ArticleQuery {
        ArticleQuery(
            source: source, filters: filters,
            sortField: sortField, sortOrder: sortOrder,
            limitCount: limitCount, offsetCount: count
        )
    }

    /// Returns a specific page of results.
    public func page(_ page: Int, size: Int) -> ArticleQuery {
        ArticleQuery(
            source: source, filters: filters,
            sortField: sortField, sortOrder: sortOrder,
            limitCount: size, offsetCount: (page - 1) * size
        )
    }

    // MARK: - Evaluation

    /// All articles matching the current filters, sorted and paginated.
    public var all: [Article] {
        var result = filtered

        if let field = sortField {
            result.sort { a, b in
                switch (field, sortOrder) {
                case (.date, .forward): a.date < b.date
                case (.date, .reverse): a.date > b.date
                case (.title, .forward): a.title < b.title
                case (.title, .reverse): a.title > b.title
                }
            }
        }

        if let offset = offsetCount {
            result = Array(result.dropFirst(offset))
        }

        if let limit = limitCount {
            result = Array(result.prefix(limit))
        }

        return result
    }

    /// The number of results after filtering, sorting, and pagination.
    public var count: Int { all.count }

    /// The first result, if any.
    public var first: Article? { all.first }

    /// The total number of filtered results, ignoring limit and offset.
    public var totalCount: Int { filtered.count }

    // MARK: - Private

    private var filtered: [Article] {
        source.filter { article in
            filters.allSatisfy { $0.matches(article) }
        }
    }

    private func adding(_ filter: ArticleFilter) -> ArticleQuery {
        ArticleQuery(
            source: source, filters: filters + [filter],
            sortField: sortField, sortOrder: sortOrder,
            limitCount: limitCount, offsetCount: offsetCount
        )
    }
}

// MARK: - ArticleFilter

private enum ArticleFilter: Sendable {
    case tagged(String)
    case taggedAnyOf([String])
    case taggedAllOf([String])
    case author(String)
    case published
    case after(Date)
    case before(Date)
    case between(Date, Date)
    case metadata(String, String)
    case custom(@Sendable (Article) -> Bool)

    func matches(_ article: Article) -> Bool {
        switch self {
        case .tagged(let tag):
            return article.tags?.contains(tag) ?? false
        case .taggedAnyOf(let tags):
            guard let articleTags = article.tags else { return false }
            return tags.contains { articleTags.contains($0) }
        case .taggedAllOf(let tags):
            guard let articleTags = article.tags else { return false }
            return tags.allSatisfy { articleTags.contains($0) }
        case .author(let name):
            return article.author == name
        case .published:
            return article.isPublished
        case .after(let date):
            return article.date > date
        case .before(let date):
            return article.date < date
        case .between(let start, let end):
            return article.date >= start && article.date < end
        case .metadata(let key, let value):
            return (article.metadata[key] as? String) == value
        case .custom(let predicate):
            return predicate(article)
        }
    }
}
