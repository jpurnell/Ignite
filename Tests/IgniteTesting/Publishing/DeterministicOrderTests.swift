//
//  DeterministicOrderTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that output which depended on the order a file system lists files in, or on the
/// time of the build, depends on neither.
@Suite("Deterministic Order Tests")
struct DeterministicOrderTests {
    /// Creates an empty temporary site and returns its root, source and build directories.
    private func makeSite() throws -> (root: URL, source: URL, build: URL) {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-order-\(UUID().uuidString)")
        let source = root.appending(path: "Source")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        return (root, source, root.appending(path: "Build"))
    }

    private func remove(_ root: URL) {
        do {
            try FileManager.default.removeItem(at: root)
        } catch {
            Issue.record("Could not remove temporary site: \(error)")
        }
    }

    @Test("An image's variants are listed in name order")
    func imageVariantsAreSorted() throws {
        let site = try makeSite()
        defer { remove(site.root) }

        let images = site.source.appending(path: "Assets/images")
        try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)

        // Written in an order that is not name order, in case the file system keeps it.
        for name in ["photo@3x.jpg", "photo.jpg", "photo@4x.jpg", "photo@2x.jpg"] {
            try Data(name.utf8).write(to: images.appending(path: name))
        }

        let context = try PublishingContext.initialize(
            for: TestSite(),
            sourceDirectory: site.source,
            buildDirectory: site.build
        )

        PublishingContext.withCurrent(context) {
            #expect(Image("/images/photo.jpg", description: "Photo").markupString() == """
            <img src="/images/photo.jpg" alt="Photo" \
            srcset="/images/photo@2x.jpg 2x, /images/photo@3x.jpg 3x, /images/photo@4x.jpg 4x" />
            """)
        }
    }

    @Test("Articles with the same date are ordered by path")
    func articlesWithEqualDatesAreOrderedByPath() throws {
        let site = try makeSite()
        defer { remove(site.root) }

        let content = site.source.appending(path: "Content/posts")
        try FileManager.default.createDirectory(at: content, withIntermediateDirectories: true)

        // Same date throughout, written in an order that is not path order.
        for name in ["delta", "alpha", "charlie", "bravo", "echo"] {
            try "---\ndate: 2024-03-05 10:00\n---\n# \(name)\n\nText."
                .write(to: content.appending(path: "\(name).md"), atomically: true, encoding: .utf8)
        }

        try "---\ndate: 2024-03-06 10:00\n---\n# newest\n\nText."
            .write(to: content.appending(path: "zulu.md"), atomically: true, encoding: .utf8)

        let context = try PublishingContext.initialize(
            for: TestSite(),
            sourceDirectory: site.source,
            buildDirectory: site.build
        )
        try context.parseContent()

        // Newest first, as before; within a date, by path.
        #expect(context.allContent.map(\.path) == [
            "/posts/zulu", "/posts/alpha", "/posts/bravo", "/posts/charlie", "/posts/delta", "/posts/echo"
        ])
    }

    @Test("An Atom feed with no entries does not carry the time of the build")
    func emptyAtomFeedHasAFixedDate() throws {
        let config = try #require(FeedConfiguration(mode: .descriptionOnly, contentCount: 20))
        let feed = AtomFeedGenerator(config: config, site: TestSite(), content: []).generateFeed()

        #expect(feed.contains("<updated>1970-01-01T00:00:00Z</updated>"))
    }

    @Test("An Atom feed with entries is dated by its newest entry, as before")
    func atomFeedIsDatedByNewestEntry() throws {
        let config = try #require(FeedConfiguration(mode: .descriptionOnly, contentCount: 20))
        var article = Article()
        article.title = "Story"
        article.path = "/story"
        article.metadata["date"] = Date(timeIntervalSince1970: 1_700_000_000)

        let site = TestSite(timeZone: .gmt)
        let feed = AtomFeedGenerator(config: config, site: site, content: [article]).generateFeed()

        #expect(feed.contains("<updated>2023-11-14T22:13:20Z</updated><generator"))
    }
}
