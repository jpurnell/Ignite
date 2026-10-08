//
// FileURLAddresses.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for addresses given as `file:` URLs.
///
/// A `file:` URL is an address with a scheme, like `tel:` or `https:`: it is the author's,
/// and is written as it was given on every kind of site. It used to be appended to the
/// site's own path, which produced an address that named nothing.
@Suite("File URL Address Tests")
struct FileURLAddressTests {
    @Test("A link to a file URL is written as authored", arguments: [
        TestPublishingSite.standard, .subsite, .relativePaths, .relativePathsSubsite
    ])
    func linkToFileURL(site: TestPublishingSite) throws {
        try PublishingContext.withInitialized(for: site.site, from: #filePath) { _ in
            #expect(Link("Manual", target: "file:///Users/me/manual.pdf").markupString()
                == #"<a href="file:///Users/me/manual.pdf">Manual</a>"#)
            #expect(Link("Manual", target: URL(fileURLWithPath: "/Users/me/manual.pdf")).markupString()
                == #"<a href="file:///Users/me/manual.pdf">Manual</a>"#)
        }
    }

    @Test("A script given as a file URL is written as authored", arguments: [
        TestPublishingSite.standard, .subsite, .relativePaths, .relativePathsSubsite
    ])
    func scriptFromFileURL(site: TestPublishingSite) throws {
        try PublishingContext.withInitialized(for: site.site, from: #filePath) { _ in
            #expect(Script(file: URL(fileURLWithPath: "/Users/me/site.js")).markupString()
                == #"<script src="file:///Users/me/site.js"></script>"#)
        }
    }

    @Test("The address of a file URL is the URL itself", arguments: [
        TestPublishingSite.standard, .subsite, .relativePaths, .relativePathsSubsite
    ])
    func pathForFileURL(site: TestPublishingSite) throws {
        try PublishingContext.withInitialized(for: site.site, from: #filePath) { context in
            #expect(context.path(for: URL(fileURLWithPath: "/Users/me/a.png")) == "file:///Users/me/a.png")
        }
    }

    @Test("Addresses that are not file URLs are resolved as before")
    func otherAddressesUnchanged() throws {
        try PublishingContext.withInitialized(for: TestSubsite(), from: #filePath) { context in
            #expect(context.path(for: URL(static: "https://example.com/a")) == "https://example.com/a")
            #expect(context.path(for: URL(static: "/about")) == "/about")
            #expect(context.path(for: URL(static: "about")) == "about")
            #expect(context.path(for: URL(static: "//cdn.example.com/a.js")) == "//cdn.example.com/a.js")
        }
    }
}
