//
//  SearchEntryTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `SearchEntry` type.
@Suite("SearchEntry Tests")
struct SearchEntryTests {

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let entry = SearchEntry(
            title: "Test Article",
            description: "A test description",
            url: "/blog/test-article",
            tags: ["swift", "testing"],
            author: "Alice",
            excerpt: "This is an excerpt...",
            date: "2026-01-15T00:00:00Z",
            tokens: ["test", "articl", "swift"]
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(SearchEntry.self, from: data)

        #expect(decoded.title == "Test Article")
        #expect(decoded.description == "A test description")
        #expect(decoded.url == "/blog/test-article")
        #expect(decoded.tags == ["swift", "testing"])
        #expect(decoded.author == "Alice")
        #expect(decoded.excerpt == "This is an excerpt...")
        #expect(decoded.date == "2026-01-15T00:00:00Z")
        #expect(decoded.tokens == ["test", "articl", "swift"])
    }

    @Test("Empty fields encode correctly")
    func emptyFields() throws {
        let entry = SearchEntry(
            title: "",
            description: "",
            url: "/",
            tags: [],
            author: "",
            excerpt: "",
            date: "",
            tokens: []
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(SearchEntry.self, from: data)

        #expect(decoded.title.isEmpty)
        #expect(decoded.tags.isEmpty)
        #expect(decoded.tokens.isEmpty)
    }
}
