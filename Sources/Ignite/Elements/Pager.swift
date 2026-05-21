//
//  Pager.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// A navigation component that renders Bootstrap 5 pagination controls.
public struct Pager: HTML {
    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The visual style for the pager.
    public enum Style: Sendable {
        /// Previous/Next links only.
        case prevNext

        /// Numbered page links with prev/next.
        case numbered

        /// Numbered with ellipsis for large page counts.
        case compact
    }

    private let context: PaginationContext
    private let style: Style
    private let maxVisiblePages: Int

    /// Creates a pagination navigation component.
    /// - Parameters:
    ///   - context: The pagination state to render.
    ///   - style: The visual style. Defaults to `.numbered`.
    ///   - maxVisiblePages: Max page links in compact mode. Defaults to 7.
    public init(context: PaginationContext, style: Style = .numbered, maxVisiblePages: Int = 7) {
        self.context = context
        self.style = style
        self.maxVisiblePages = maxVisiblePages
    }

    public func markup() -> Markup {
        guard context.totalPages > 1 else {
            return Markup("")
        }

        var items = [String]()

        let prevDisabled = context.hasPreviousPage ? "" : " disabled"
        let prevHref = context.previousPagePath ?? "#"
        items.append("""
        <li class="page-item\(prevDisabled)">\
        <a class="page-link" href="\(prevHref)">Previous</a></li>
        """)

        switch style {
        case .prevNext:
            break
        case .numbered:
            for page in 1...context.totalPages {
                let active = page == context.currentPage ? " active" : ""
                let href = context.path(forPage: page)
                items.append("""
                <li class="page-item\(active)">\
                <a class="page-link" href="\(href)">\(page)</a></li>
                """)
            }
        case .compact:
            let pageNumbers = compactPageNumbers()
            for entry in pageNumbers {
                if entry == 0 {
                    items.append("""
                    <li class="page-item disabled">\
                    <span class="page-link">&hellip;</span></li>
                    """)
                } else {
                    let active = entry == context.currentPage ? " active" : ""
                    let href = context.path(forPage: entry)
                    items.append("""
                    <li class="page-item\(active)">\
                    <a class="page-link" href="\(href)">\(entry)</a></li>
                    """)
                }
            }
        }

        let nextDisabled = context.hasNextPage ? "" : " disabled"
        let nextHref = context.nextPagePath ?? "#"
        items.append("""
        <li class="page-item\(nextDisabled)">\
        <a class="page-link" href="\(nextHref)">Next</a></li>
        """)

        let listContent = items.joined()
        return Markup("""
        <nav aria-label="Page navigation">\
        <ul class="pagination justify-content-center">\
        \(listContent)\
        </ul></nav>
        """)
    }

    private func compactPageNumbers() -> [Int] {
        let total = context.totalPages
        let current = context.currentPage

        if total <= maxVisiblePages {
            return Array(1...total)
        }

        var pages = [Int]()
        let sideCount = (maxVisiblePages - 3) / 2

        pages.append(1)

        let leftBound = max(2, current - sideCount)
        let rightBound = min(total - 1, current + sideCount)

        if leftBound > 2 { pages.append(0) }

        for page in leftBound...rightBound {
            pages.append(page)
        }

        if rightBound < total - 1 { pages.append(0) }

        pages.append(total)

        return pages
    }
}
