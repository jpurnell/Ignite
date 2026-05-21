//
//  PaginationContext.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// Provides pagination state to the current page being rendered.
public struct PaginationContext: Sendable {
    /// The current page number (1-indexed).
    public let currentPage: Int

    /// The total number of pages.
    public let totalPages: Int

    /// The base path for this paginated section (e.g., "/blog/").
    public let basePath: String

    /// The URL path for a specific page number.
    /// Page 1 uses the base path; subsequent pages use /page/N/.
    public func path(forPage page: Int) -> String {
        guard page > 1 else { return basePath }
        return "\(basePath)page/\(page)/"
    }

    /// Whether there is a previous page.
    public var hasPreviousPage: Bool { currentPage > 1 }

    /// Whether there is a next page.
    public var hasNextPage: Bool { currentPage < totalPages }

    /// The path to the previous page, if any.
    public var previousPagePath: String? {
        guard hasPreviousPage else { return nil }
        return path(forPage: currentPage - 1)
    }

    /// The path to the next page, if any.
    public var nextPagePath: String? {
        guard hasNextPage else { return nil }
        return path(forPage: currentPage + 1)
    }

    /// Creates a pagination context.
    /// - Parameters:
    ///   - currentPage: The current page number (1-indexed).
    ///   - totalPages: The total number of pages.
    ///   - basePath: The base URL path for this paginated section.
    public init(currentPage: Int, totalPages: Int, basePath: String) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.basePath = basePath
    }
}
