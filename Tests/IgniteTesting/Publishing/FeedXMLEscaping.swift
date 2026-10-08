//
//  FeedXMLEscaping.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that article data cannot produce malformed XML in the RSS feed, the Atom feed or the sitemap.
@Suite("Feed XML Escaping Tests")
struct FeedXMLEscapingTests {
    /// An article whose every field holds something XML would misread if written as-is.
    private static var hostileArticle: Article {
        var article = Article()
        article.title = "Title"
        article.description = "Ends a section ]]> <b>early</b>"
        article.path = "/story?a=1&b=2"
        article.text = "<p>Body ]]> more</p>"
        article.metadata["date"] = Date(timeIntervalSince1970: 1_700_000_000)
        article.metadata["author"] = "A ]]> B & <C>"
        article.metadata["tags"] = "x]]>y, R&D"
        return article
    }

    private static var fullConfiguration: FeedConfiguration {
        get throws {
            try #require(FeedConfiguration(
                mode: .full,
                contentCount: 20,
                image: .init(url: "https://example.com/i.png?a=1&b=2", width: 100, height: 100)))
        }
    }

    @Test("CDATA sections in the RSS feed cannot be ended by their content", .publishingContext())
    func rssCDATACannotBeEnded() throws {
        let feed = FeedGenerator(config: try Self.fullConfiguration, site: TestSite(), content: [Self.hostileArticle])
            .generateFeed()

        #expect(feed.contains("<description><![CDATA[Ends a section ]]]]><![CDATA[> <b>early</b>]]></description>"))
        #expect(feed.contains("<dc:creator><![CDATA[A ]]]]><![CDATA[> B & <C>]]></dc:creator>"))
        #expect(feed.contains("<category><![CDATA[x]]]]><![CDATA[>y]]></category>"))
        #expect(feed.contains("<category><![CDATA[R&D]]></category>"))
        #expect(feed.contains("<![CDATA[<p>Body ]]]]><![CDATA[> more</p>]]>"))
    }

    @Test("Addresses in the RSS feed are escaped", .publishingContext())
    func rssAddressesAreEscaped() throws {
        let feed = FeedGenerator(config: try Self.fullConfiguration, site: TestSite(), content: [Self.hostileArticle])
            .generateFeed()

        #expect(feed.contains("<guid isPermaLink=\"true\">https://www.example.com/story%3Fa=1&amp;b=2</guid>"))
        #expect(feed.contains("<link>https://www.example.com/story%3Fa=1&amp;b=2</link>"))
        #expect(feed.contains("<url>https://example.com/i.png?a=1&amp;b=2</url>"))
    }

    @Test("The Atom feed's CDATA sections and addresses are escaped", .publishingContext())
    func atomIsEscaped() throws {
        let feed = AtomFeedGenerator(config: try Self.fullConfiguration, site: TestSite(), content: [Self.hostileArticle])
            .generateFeed()

        #expect(feed.contains("<summary type=\"html\"><![CDATA[Ends a section ]]]]><![CDATA[> <b>early</b>]]></summary>"))
        #expect(feed.contains("<![CDATA[<p>Body ]]]]><![CDATA[> more</p>]]>"))
        #expect(feed.contains("<link href=\"https://www.example.com/story%3Fa=1&amp;b=2\" rel=\"alternate\"/>"))
        #expect(feed.contains("<id>https://www.example.com/story%3Fa=1&amp;b=2</id>"))
        #expect(feed.contains("<icon>https://example.com/i.png?a=1&amp;b=2</icon>"))
        #expect(feed.contains("<logo>https://example.com/i.png?a=1&amp;b=2</logo>"))
    }

    @Test("A sitemap location is escaped", .publishingContext())
    func sitemapLocationIsEscaped() throws {
        let context = try PublishingContext.initialize(for: TestSite(), from: #filePath)
        context.addToSiteMap("/a&b", priority: 0.5)

        #expect(SiteMapGenerator(context: context).generateSiteMap()
            .contains("<url><loc>https://www.example.com/a&amp;b/</loc><priority>0.5</priority></url>"))
    }

    @Test("The language and the site address are escaped in feed headers", .publishingContext())
    func feedHeaderAddressesAreEscaped() throws {
        var site = TestSite()
        site.url = try #require(URL(string: "https://www.example.com/a&b"))

        let rss = FeedGenerator(config: try Self.fullConfiguration, site: site, content: []).generateFeed()
        #expect(rss.contains("<link>https://www.example.com/a&amp;b</link>"))
        #expect(rss.contains("href=\"https://www.example.com/a&amp;b/feed.rss\""))

        let atom = AtomFeedGenerator(config: try Self.fullConfiguration, site: site, content: []).generateFeed()
        #expect(atom.contains("<link href=\"https://www.example.com/a&amp;b\" rel=\"alternate\"/>"))
        #expect(atom.contains("<link href=\"https://www.example.com/a&amp;b/feed.atom\" rel=\"self\" type=\"application/atom+xml\"/>"))
        #expect(atom.contains("<id>https://www.example.com/a&amp;b/</id>"))
    }
}
