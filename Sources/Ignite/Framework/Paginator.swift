//
//  Paginator.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// Splits a collection of content into fixed-size pages for multi-page rendering.
public struct Paginator<Content: Sendable>: Sendable {
    /// All items being paginated.
    public let allItems: [Content]

    /// The number of items per page.
    public let pageSize: Int

    /// The total number of pages.
    public var pageCount: Int {
        guard !allItems.isEmpty else { return 1 }
        return Int(ceil(Double(allItems.count) / Double(pageSize)))
    }

    /// The items for a specific page (1-indexed).
    public func items(forPage page: Int) -> [Content] {
        guard page >= 1, page <= pageCount, !allItems.isEmpty else { return [] }
        let start = (page - 1) * pageSize
        let end = min(start + pageSize, allItems.count)
        return Array(allItems[start..<end])
    }

    /// Creates a paginator for the given items.
    /// - Parameters:
    ///   - items: The full collection to paginate.
    ///   - pageSize: Number of items per page. Clamped to a minimum of 1. Defaults to 10.
    public init(_ items: [Content], pageSize: Int = 10) {
        self.allItems = items
        self.pageSize = max(1, pageSize)
    }
}
