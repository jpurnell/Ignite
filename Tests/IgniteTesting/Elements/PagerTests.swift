//
//  PagerTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `Pager` element.
@Suite("Pager Tests")
class PagerTests: IgniteTestSuite {

    // MARK: - prevNext style

    @Test("prevNext on first page disables Previous, enables Next", .publishingContext())
    func prevNextFirstPage() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 3, basePath: "/blog/")
        let output = Pager(context: context, style: .prevNext).markupString()

        #expect(output.contains("aria-label=\"Page navigation\""))
        #expect(output.contains("disabled"))
        #expect(output.contains("Previous"))
        #expect(output.contains("href=\"/blog/page/2/\""))
        #expect(output.contains("Next"))
    }

    @Test("prevNext on last page enables Previous, disables Next", .publishingContext())
    func prevNextLastPage() async throws {
        let context = PaginationContext(currentPage: 3, totalPages: 3, basePath: "/blog/")
        let output = Pager(context: context, style: .prevNext).markupString()

        #expect(output.contains("href=\"/blog/page/2/\""))
        #expect(output.contains("Previous"))
        let nextDisabled = output.contains("disabled") && output.contains("Next")
        #expect(nextDisabled)
    }

    @Test("prevNext on middle page enables both", .publishingContext())
    func prevNextMiddlePage() async throws {
        let context = PaginationContext(currentPage: 2, totalPages: 3, basePath: "/blog/")
        let output = Pager(context: context, style: .prevNext).markupString()

        #expect(output.contains("href=\"/blog/\""))
        #expect(output.contains("href=\"/blog/page/3/\""))
    }

    // MARK: - numbered style

    @Test("numbered style shows all page numbers", .publishingContext())
    func numberedShowsAll() async throws {
        let context = PaginationContext(currentPage: 2, totalPages: 3, basePath: "/blog/")
        let output = Pager(context: context, style: .numbered).markupString()

        #expect(output.contains("href=\"/blog/\""))
        #expect(output.contains("href=\"/blog/page/2/\""))
        #expect(output.contains("href=\"/blog/page/3/\""))
    }

    @Test("numbered style marks current page as active", .publishingContext())
    func numberedActiveClass() async throws {
        let context = PaginationContext(currentPage: 2, totalPages: 3, basePath: "/blog/")
        let output = Pager(context: context, style: .numbered).markupString()

        #expect(output.contains("active"))
    }

    @Test("numbered style uses Bootstrap pagination classes", .publishingContext())
    func numberedBootstrapClasses() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 2, basePath: "/blog/")
        let output = Pager(context: context, style: .numbered).markupString()

        #expect(output.contains("pagination"))
        #expect(output.contains("page-item"))
        #expect(output.contains("page-link"))
    }

    // MARK: - compact style

    @Test("compact style uses ellipsis for many pages", .publishingContext())
    func compactEllipsis() async throws {
        let context = PaginationContext(currentPage: 5, totalPages: 20, basePath: "/blog/")
        let output = Pager(context: context, style: .compact, maxVisiblePages: 7).markupString()

        #expect(output.contains("&hellip;"))
    }

    @Test("compact style shows all pages when count is small", .publishingContext())
    func compactNoEllipsisWhenSmall() async throws {
        let context = PaginationContext(currentPage: 2, totalPages: 5, basePath: "/blog/")
        let output = Pager(context: context, style: .compact, maxVisiblePages: 7).markupString()

        #expect(!output.contains("&hellip;"))
    }

    // MARK: - single page

    @Test("Single page renders empty", .publishingContext())
    func singlePageEmpty() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 1, basePath: "/blog/")
        let output = Pager(context: context).markupString()

        #expect(!output.contains("page-item"))
    }

    // MARK: - default style

    @Test("Default style is numbered", .publishingContext())
    func defaultIsNumbered() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 3, basePath: "/blog/")
        let output = Pager(context: context).markupString()

        #expect(output.contains("page-item"))
        #expect(output.contains(">1<"))
        #expect(output.contains(">2<"))
        #expect(output.contains(">3<"))
    }
}
