//
//  FeedLink.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `FeedLink` component.
@Suite("FeedLink Tests")
class FeedLinkTests: IgniteTestSuite {
    /// Creates an environment with feed configuration from TestSite.
    private func environmentWithFeed() -> EnvironmentValues {
        EnvironmentValues(
            sourceDirectory: publishingContext.sourceDirectory,
            site: TestSite(),
            allContent: []
        )
    }

    @Test("Renders RSS Feed link when feed is configured", .publishingContext())
    func rendersRSSFeedLink() async throws {
        let output = publishingContext.withEnvironment(environmentWithFeed()) {
            FeedLink().markupString()
        }
        #expect(output.contains("RSS Feed"))
        #expect(output.contains("/feed.rss"))
    }

    @Test("Renders as centered text", .publishingContext())
    func renderedAsCenteredText() async throws {
        let output = publishingContext.withEnvironment(environmentWithFeed()) {
            FeedLink().markupString()
        }
        #expect(output.contains("text-center"))
    }

    @Test("Contains link element pointing to feed path", .publishingContext())
    func containsLinkElement() async throws {
        let output = publishingContext.withEnvironment(environmentWithFeed()) {
            FeedLink().markupString()
        }
        #expect(output.contains("<a"))
        #expect(output.contains("href=\"/feed.rss\""))
    }

    @Test("Includes RSS icon when built-in icons are enabled", .publishingContext())
    func includesRSSIcon() async throws {
        let output = publishingContext.withEnvironment(environmentWithFeed()) {
            FeedLink().markupString()
        }
        #expect(output.contains("rss-fill"))
    }

    @Test("Renders empty when no feed is configured", .publishingContext())
    func rendersEmptyWithoutFeedConfig() async throws {
        let element = FeedLink()
        let output = element.markupString()
        #expect(output == "")
    }

    @Test("On a site deployed in a subdirectory the feed links lead into the site",
          .publishingContext(.subsite))
    func feedLinksOnSubsite() async throws {
        let environment = EnvironmentValues(
            sourceDirectory: publishingContext.sourceDirectory,
            site: FeedLinkAllFormatsSite(),
            allContent: [])
        let output = publishingContext.withEnvironment(environment) {
            FeedLink().markupString()
        }
        #expect(output.contains(#"<a href="/subsite/feed.atom">Atom Feed</a>"#))
        #expect(output.contains(#"<a href="/subsite/feed.json">JSON Feed</a>"#))
        #expect(output.contains(#"<a href="/subsite/feed.rss">RSS Feed</a>"#))
    }

    @Test("Each feed is named once: the JSON Feed is not the JSON Feed Feed", .publishingContext())
    func feedNames() async throws {
        #expect(FeedFormat.rss.linkTitle == "RSS Feed")
        #expect(FeedFormat.atom.linkTitle == "Atom Feed")
        #expect(FeedFormat.json.linkTitle == "JSON Feed")

        let config = try #require(FeedConfiguration(mode: .full, contentCount: 20, formats: [.rss, .atom, .json]))
        let links = MetaLink.feedDiscoveryLinks(for: config).markupString()
        #expect(links == """
        <link type="application/atom+xml" title="Atom Feed" href="/feed.atom" rel="alternate" />\
        <link type="application/feed+json" title="JSON Feed" href="/feed.json" rel="alternate" />\
        <link type="application/rss+xml" title="RSS Feed" href="/feed.rss" rel="alternate" />
        """)
    }
}

/// A site at a subdirectory with every feed format switched on.
private struct FeedLinkAllFormatsSite: Site {
    var name = "Feeds"
    var url = URL(static: "https://www.example.com/subsite")
    var homePage = TestSubsitePage()
    var layout = EmptyLayout()

    var feedConfiguration: FeedConfiguration? {
        FeedConfiguration(mode: .full, contentCount: 20, formats: [.rss, .atom, .json])
    }
}
