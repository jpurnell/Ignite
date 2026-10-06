//
// FeedGenerator.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

enum FeedSite: Sendable {
    case standard
    case gmt
    case est

    static let all: [Self] = [.standard, .gmt, .est]

    var site: TestSite {
        get throws {
            switch self {
            case .standard:
                TestSite()
            case .gmt:
                TestSite(timeZone: try #require(TimeZone(abbreviation: "GMT")))
            case .est:
                TestSite(timeZone: try #require(TimeZone(abbreviation: "EST")))
            }
        }
    }
}

/// Tests for the `FeedGenerator` type.
@Suite("FeedGenerator Tests")
struct FeedGeneratorTests {
    @Test("XML-escapes special characters in titles", .publishingContext())
    func xmlEscapesSpecialCharacters() async throws {
        let site = TestSite()
        let config = try #require(site.feedConfiguration)
        var article = Article()
        article.title = "Donations & Sponsorships"
        article.description = "Example Description"

        let generator = FeedGenerator(config: config, site: site, content: [article])
        let feed = generator.generateFeed()

        #expect(feed.contains("<title>Donations &amp; Sponsorships</title>"))
        #expect(!feed.contains("<title>Donations & Sponsorships</title>"))
    }

    @Test("generateFeed()", .publishingContext(), arguments: FeedSite.all)
    func generateFeed(for siteCase: FeedSite) async throws {
        let site = try siteCase.site
        let config = try #require(site.feedConfiguration)
        let feedHref = site.url.appending(path: config.path).absoluteString
        var exampleContent = Article()
        exampleContent.title = "Example Title"
        exampleContent.description = "Example Description"
        // Without a date in its metadata an article reports the current time on every read,
        // so the feed and the expectation below would each take their own clock reading.
        exampleContent.metadata["date"] = Date(timeIntervalSince1970: 1_700_000_000)

        let generator = FeedGenerator(config: config, site: site, content: [exampleContent])

        #expect(generator.generateFeed() == """
        <?xml version="1.0" encoding="UTF-8" ?>\
        <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" \
        xmlns:atom="http://www.w3.org/2005/Atom" \
        xmlns:content="http://purl.org/rss/1.0/modules/content/">\
        <channel>\
        <title>\(site.name)</title>\
        <description>\(site.description ?? "")</description>\
        <link>\(site.url.absoluteString)</link>\
        <atom:link
            href="\(feedHref)"
            rel="self" type="application/rss+xml"
        />\
        <language>\(site.language.rawValue)</language>\
        <generator>\(Ignite.version)</generator>\
        <image>\
        <url>\(config.image?.url ?? "")</url>\
        <title>\(site.name)</title>\
        <link>\(site.url.absoluteString)</link>\
        <width>\(config.image?.width ?? 0)</width>\
        <height>\(config.image?.height ?? 0)</height>\
        </image>\
        <item>\
        <guid isPermaLink="true">\(exampleContent.path(in: site))</guid>\
        <title>\(exampleContent.title)</title>\
        <link>\(exampleContent.path(in: site))</link>\
        <description><![CDATA[\(exampleContent.description)]]></description>\
        <pubDate>\(exampleContent.date.asRFC822(timeZone: site.timeZone))</pubDate>\
        </item>\
        </channel>\
        </rss>
        """)
    }
}
