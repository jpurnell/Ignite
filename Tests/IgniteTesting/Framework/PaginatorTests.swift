//
//  PaginatorTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `Paginator` type and `PaginationContext`.
@Suite("Paginator Tests")
struct PaginatorTests {

    // MARK: - Paginator: page count

    @Test("25 items with pageSize 10 produces 3 pages", .publishingContext())
    func pageCountStandard() async throws {
        let items = Array(1...25)
        let paginator = Paginator(items, pageSize: 10)
        #expect(paginator.pageCount == 3)
    }

    @Test("10 items with pageSize 10 produces exactly 1 page", .publishingContext())
    func pageCountExact() async throws {
        let items = Array(1...10)
        let paginator = Paginator(items, pageSize: 10)
        #expect(paginator.pageCount == 1)
    }

    @Test("0 items produces 1 page", .publishingContext())
    func pageCountEmpty() async throws {
        let paginator = Paginator([Int](), pageSize: 10)
        #expect(paginator.pageCount == 1)
    }

    @Test("1 item produces 1 page", .publishingContext())
    func pageCountSingle() async throws {
        let paginator = Paginator([42], pageSize: 10)
        #expect(paginator.pageCount == 1)
    }

    @Test("pageSize 1 produces N pages", .publishingContext())
    func pageCountSizeOne() async throws {
        let items = Array(1...5)
        let paginator = Paginator(items, pageSize: 1)
        #expect(paginator.pageCount == 5)
    }

    @Test("Very large pageSize produces 1 page", .publishingContext())
    func pageCountLargeSize() async throws {
        let items = Array(1...5)
        let paginator = Paginator(items, pageSize: 1000)
        #expect(paginator.pageCount == 1)
    }

    @Test("Constructor clamps pageSize to minimum of 1", .publishingContext())
    func pageSizeClamped() async throws {
        let paginator = Paginator([1, 2, 3], pageSize: 0)
        #expect(paginator.pageSize == 1)
        #expect(paginator.pageCount == 3)

        let negPaginator = Paginator([1, 2, 3], pageSize: -5)
        #expect(negPaginator.pageSize == 1)
    }

    @Test("Default pageSize is 10", .publishingContext())
    func defaultPageSize() async throws {
        let paginator = Paginator(Array(1...25))
        #expect(paginator.pageSize == 10)
        #expect(paginator.pageCount == 3)
    }

    // MARK: - Paginator: items(forPage:)

    @Test("Page 1 returns first pageSize items", .publishingContext())
    func itemsFirstPage() async throws {
        let items = Array(1...25)
        let paginator = Paginator(items, pageSize: 10)
        #expect(paginator.items(forPage: 1) == Array(1...10))
    }

    @Test("Last page returns remaining items", .publishingContext())
    func itemsLastPage() async throws {
        let items = Array(1...25)
        let paginator = Paginator(items, pageSize: 10)
        #expect(paginator.items(forPage: 3) == Array(21...25))
    }

    @Test("Middle page returns correct slice", .publishingContext())
    func itemsMiddlePage() async throws {
        let items = Array(1...25)
        let paginator = Paginator(items, pageSize: 10)
        #expect(paginator.items(forPage: 2) == Array(11...20))
    }

    @Test("Page 0 returns empty array", .publishingContext())
    func itemsPageZero() async throws {
        let paginator = Paginator(Array(1...10), pageSize: 5)
        #expect(paginator.items(forPage: 0).isEmpty)
    }

    @Test("Negative page returns empty array", .publishingContext())
    func itemsNegativePage() async throws {
        let paginator = Paginator(Array(1...10), pageSize: 5)
        #expect(paginator.items(forPage: -1).isEmpty)
    }

    @Test("Page beyond pageCount returns empty array", .publishingContext())
    func itemsBeyondRange() async throws {
        let paginator = Paginator(Array(1...10), pageSize: 5)
        #expect(paginator.items(forPage: 3).isEmpty)
    }

    @Test("Empty paginator returns empty for page 1", .publishingContext())
    func itemsEmptyPaginator() async throws {
        let paginator = Paginator([Int](), pageSize: 10)
        #expect(paginator.items(forPage: 1).isEmpty)
    }

    // MARK: - Paginator: allItems preserved

    @Test("allItems preserves input order", .publishingContext())
    func allItemsPreserved() async throws {
        let items = [5, 3, 1, 4, 2]
        let paginator = Paginator(items, pageSize: 2)
        #expect(paginator.allItems == [5, 3, 1, 4, 2])
    }
}

/// Tests for the `PaginationContext` type.
@Suite("PaginationContext Tests")
struct PaginationContextTests {

    // MARK: - Path generation

    @Test("Page 1 uses base path", .publishingContext())
    func pathPageOne() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 3, basePath: "/blog/")
        #expect(context.path(forPage: 1) == "/blog/")
    }

    @Test("Page 2 uses /page/2/ suffix", .publishingContext())
    func pathPageTwo() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 3, basePath: "/blog/")
        #expect(context.path(forPage: 2) == "/blog/page/2/")
    }

    @Test("Page 3 uses /page/3/ suffix", .publishingContext())
    func pathPageThree() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 5, basePath: "/blog/")
        #expect(context.path(forPage: 3) == "/blog/page/3/")
    }

    // MARK: - Navigation helpers

    @Test("Page 1 has no previous page", .publishingContext())
    func noPreviousOnFirstPage() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 3, basePath: "/blog/")
        #expect(context.hasPreviousPage == false)
        #expect(context.previousPagePath == nil)
    }

    @Test("Last page has no next page", .publishingContext())
    func noNextOnLastPage() async throws {
        let context = PaginationContext(currentPage: 3, totalPages: 3, basePath: "/blog/")
        #expect(context.hasNextPage == false)
        #expect(context.nextPagePath == nil)
    }

    @Test("Middle page has both previous and next", .publishingContext())
    func middlePageHasBoth() async throws {
        let context = PaginationContext(currentPage: 2, totalPages: 3, basePath: "/blog/")
        #expect(context.hasPreviousPage == true)
        #expect(context.hasNextPage == true)
        #expect(context.previousPagePath == "/blog/")
        #expect(context.nextPagePath == "/blog/page/3/")
    }

    @Test("Previous page from page 3 is /page/2/", .publishingContext())
    func previousPagePath() async throws {
        let context = PaginationContext(currentPage: 3, totalPages: 5, basePath: "/blog/")
        #expect(context.previousPagePath == "/blog/page/2/")
    }

    @Test("Single-page context has neither previous nor next", .publishingContext())
    func singlePage() async throws {
        let context = PaginationContext(currentPage: 1, totalPages: 1, basePath: "/blog/")
        #expect(context.hasPreviousPage == false)
        #expect(context.hasNextPage == false)
    }

    // MARK: - Properties

    @Test("Context exposes current page and total pages", .publishingContext())
    func properties() async throws {
        let context = PaginationContext(currentPage: 2, totalPages: 5, basePath: "/articles/")
        #expect(context.currentPage == 2)
        #expect(context.totalPages == 5)
    }
}
