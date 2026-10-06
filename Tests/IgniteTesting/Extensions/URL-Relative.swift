//
//  URL-Relative.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `URL-Relative` extension.
@Suite("URL-Relative Tests")
struct URLRelativeTests {
    @Test("For URL with a matching base path", .publishingContext())
    func relativePath_forURLWithAMatchingBasePath() async throws {
        // Given
        let fullURL = try #require(URL(string: "https://example.com/folder/subfolder/file.html"))
        let baseURL = try #require(URL(string: "https://example.com/folder/"))
        // When
        let relativePath = fullURL.relative(to: baseURL)
        // Then
        #expect(relativePath == "subfolder/file.html")
    }

    @Test("For URL with no common base", .publishingContext())
    func relativePath_forURLWithNoCommonBase() async throws {
        // Given
        let fullURL = try #require(URL(string: "https://example.com/folder/file.html"))
        let baseURL = try #require(URL(string: "https://another.com/"))
        // When
        let relativePath = fullURL.relative(to: baseURL)
        // Then
        #expect(relativePath == "folder/file.html") // Full path since no overlap exists
    }

    @Test("For an identical URL", .publishingContext())
    func relativePath_forAnIdenticalURL() async throws {
        // Given
        let fullURL = try #require(URL(string: "https://example.com/folder/file.html"))
        let baseURL = try #require(URL(string: "https://example.com/folder/file.html"))
        // When
        let relativePath = fullURL.relative(to: baseURL)
        // Then
        #expect(relativePath == "") // No difference between the URLs
    }

    @Test("For base URL without a trailing slash", .publishingContext())
    func relativePath_forBaseURLWithoutTrailingSlash() async throws {
        // Given
        let fullURL = try #require(URL(string: "https://example.com/folder/subfolder/file.html"))
        let baseURL = try #require(URL(string: "https://example.com/folder"))
        // When
        let relativePath = fullURL.relative(to: baseURL)
        // Then
        #expect(relativePath == "/subfolder/file.html") // Base path isn't cleanly trimmed
    }

    @Test("For base URL WITH a trailing slash", .publishingContext())
    func relativePath_forBaseURLWithTrailingSlash() async throws {
        // Given
        let fullURL = try #require(URL(string: "https://example.com/folder/subfolder/file.html"))
        let baseURL = try #require(URL(string: "https://example.com/folder/"))
        // When
        let relativePath = fullURL.relative(to: baseURL)
        // Then
        #expect(relativePath == "subfolder/file.html")
    }

    @Test("For URLs with NO scheme", .publishingContext())
    func relativePath_forURLsWithNoScheme() async throws {
        // Given
        let fullURL1 = try #require(URL(string: "/folder/file.html")) // with leading slash
        let fullURL2 = try #require(URL(string: "folder/file.html")) // without leading slash
        let baseURL = try #require(URL(string: "https://example.com/"))
        // When
        let relativePath1 = fullURL1.relative(to: baseURL)
        let relativePath2 = fullURL2.relative(to: baseURL)
        // Then
        #expect(relativePath1 == "folder/file.html")
        #expect(relativePath2 == "folder/file.html")
    }

    @Test("For URLs with different schemes", .publishingContext())
    func relativePath_forURLsWithDifferentSchemes() async throws {
        // Given
        let baseURL = try #require(URL(string: "https://example.com/"))

        // The same address under each scheme; only the scheme differs from the base.
        for scheme in ["ftp", "http", "lol", "bla"] {
            var components = URLComponents()
            components.scheme = scheme
            components.host = "example.com"
            components.path = "/folder/file.txt"
            let fullURL = try #require(components.url)
            #expect(fullURL.scheme == scheme)
            // When
            let relativePath = fullURL.relative(to: baseURL)
            // Then
            #expect(relativePath == "folder/file.txt", "scheme: \(scheme)")
        }
    }

    @Test("For invalid base URLs", .publishingContext())
    func relativePath_forInvalidBaseURLs() async throws {
        // Given
        let fullURL = try #require(URL(string: "https://example.com/folder/file.txt"))
        let baseURL1 = try #require(URL(string: "ftp://example.com/")) // notice single slash at the end
        let baseURL2 = try #require(URL(string: "it://example.com"))
        let baseURL3 = try #require(URL(string: "lol://example."))
        let baseURL4 = try #require(URL(string: "htp://exam/")) // notice single slash at the end
        let baseURL5 = try #require(URL(string: "ftp://"))
        let baseURL6 = try #require(URL(string: "inv:/")) // notice single slash at the end
        let baseURL7 = try #require(URL(string: "ftp"))
        let baseURL8 = try #require(URL(string: "ft"))
        let baseURL9 = try #require(URL(string: " "))
        // When
        let relativePath1 = fullURL.relative(to: baseURL1)
        let relativePath2 = fullURL.relative(to: baseURL2)
        let relativePath3 = fullURL.relative(to: baseURL3)
        let relativePath4 = fullURL.relative(to: baseURL4)
        let relativePath5 = fullURL.relative(to: baseURL5)
        let relativePath6 = fullURL.relative(to: baseURL6)
        let relativePath7 = fullURL.relative(to: baseURL7)
        let relativePath8 = fullURL.relative(to: baseURL8)
        let relativePath9 = fullURL.relative(to: baseURL9)
        // Then
        #expect(relativePath1 == "folder/file.txt") // notice single slash at the start
        #expect(relativePath2 == "/folder/file.txt")
        #expect(relativePath3 == "/folder/file.txt")
        #expect(relativePath4 == "folder/file.txt") // notice single slash at the start
        #expect(relativePath5 == "/folder/file.txt")
        #expect(relativePath6 == "folder/file.txt") // notice single slash at the start
        #expect(relativePath7 == "/folder/file.txt")
        #expect(relativePath8 == "/folder/file.txt")
        #expect(relativePath9 == "/folder/file.txt")
    }

    @Test("When both URLs are incomplete", .publishingContext())
    func relativePath_whenBothURLsAreIncomplete() async throws {
        // Given
        let fullURL = try #require(URL(string: "/folder/file.html"))
        let baseURL = try #require(URL(string: "/folder/"))
        // When
        let relativePath = fullURL.relative(to: baseURL)
        // Then
        #expect(relativePath == "file.html")
        // relative path can still be calculated
    }

    @Test("For a blank URL", .publishingContext())
    func relativePath_forABlankURL() async throws {
        // Given
        let fullURL = try #require(URL(string: " "))
        let baseURL = try #require(URL(string: "https://example.com/"))
        // When
        let relativePath = fullURL.relative(to: baseURL)
        // Then
        #expect(relativePath == "%20")
        // empty input results in empty output;
        // %20 is the URL-encoded representation
        // of a space character.
    }

    @Test("For a blank base URL", .publishingContext())
    func relativePath_forABlankBaseURL() async throws {
        // Given
        let fullURL = try #require(URL(string: "https://example.com/folder/file.html"))
        let baseURL = try #require(URL(string: " "))
        // When
        let relativePath = fullURL.relative(to: baseURL)
        // Then
        #expect(relativePath == "/folder/file.html")
    }
}
