//
//  PathResolution.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A page used as a link target; its path is `/path-test-page`.
private struct PathTestPage: StaticPage {
    var title = "Path Test"
    var body: some HTML { Text("x") }
}

/// Tests for how paths within a site are written: under a subsite, with relative paths,
/// and as the absolute addresses that metadata needs.
@Suite("Path Resolution Tests")
struct PathResolutionTests {
    private static func context(_ site: TestPublishingSite) throws -> PublishingContext {
        try PublishingContext.initialize(for: site.site, from: #filePath)
    }

    private static func article(path: String, title: String = "Story") -> Article {
        var article = Article()
        article.title = title
        article.path = path
        return article
    }

    // MARK: - Relative paths are relative to the page

    @Test("A relative-path site writes paths relative to the page being rendered", arguments: [
        (0, "css/styles.css"), (1, "../css/styles.css"), (2, "../../css/styles.css")
    ])
    func relativePathsFollowPageDepth(depth: Int, expected: String) throws {
        let context = try Self.context(.relativePaths)
        context.pageDirectoryDepth = depth
        #expect(context.assetPath("/css/styles.css") == expected)
    }

    @Test("A relative-path subsite writes the same page-relative paths, without its own name", arguments: [
        (0, "css/styles.css"), (1, "../css/styles.css"), (2, "../../css/styles.css")
    ])
    func relativeSubsitePathsOmitSubsiteName(depth: Int, expected: String) throws {
        let context = try Self.context(.relativePathsSubsite)
        context.pageDirectoryDepth = depth
        #expect(context.assetPath("/css/styles.css") == expected)
    }

    @Test("A page's depth is the number of directories between it and the site root", arguments: [
        ("", 0), ("/", 0), ("/about", 1), ("about", 1), ("/blog/post/", 2), ("tags/swift", 2)
    ])
    func directoryDepth(path: String, expected: Int) {
        #expect(PublishingContext.directoryDepth(of: path) == expected)
    }

    @Test("A relative-path site links to its own pages relative to the current page")
    func relativeLinks() throws {
        let context = try Self.context(.relativePaths)

        PublishingContext.withCurrent(context) {
            #expect(Link("About", target: "/about").markupString() == #"<a href="about/">About</a>"#)
            #expect(Link("Home", target: "/").markupString() == #"<a href="./">Home</a>"#)

            context.pageDirectoryDepth = 2
            #expect(Link("About", target: "/about").markupString() == #"<a href="../../about/">About</a>"#)
            #expect(Link("Home", target: "/").markupString() == #"<a href="../../">Home</a>"#)
            #expect(Link("File", target: "/files/a.pdf").markupString() == #"<a href="../../files/a.pdf">File</a>"#)
        }
    }

    @Test("A link's trailing slash goes on the path, and only on a path", .publishingContext(), arguments: [
        ("/about#team", "/about/#team"),
        ("/about?tab=2", "/about/?tab=2"),
        ("/about/?tab=2#x", "/about/?tab=2#x"),
        ("?tab=2", "?tab=2"),
        ("#top", "#top"),
        ("/files/a.pdf#page=2", "/files/a.pdf#page=2"),
        ("about", "about/"),
        ("tel:+15551234", "tel:+15551234"),
        ("sms:+15551234", "sms:+15551234"),
        ("javascript:void(0)", "javascript:void(0)"),
        ("//cdn.example.org/a", "//cdn.example.org/a"),
        ("https://example.org/a", "https://example.org/a")
    ])
    func trailingSlash(target: String, expected: String) {
        #expect(Link("x", target: target).markupString() == "<a href=\"\(expected)\">x</a>")
    }

    @Test("A site at the root of its host writes paths and links as before", .publishingContext())
    func rootSiteIsUnchanged() {
        #expect(Link("About", target: "/about").markupString() == #"<a href="/about/">About</a>"#)
        #expect(Link("Home", target: "/").markupString() == #"<a href="/">Home</a>"#)
        #expect(Link("Home", sitePath: "/").markupString() == #"<a href="/">Home</a>"#)
        #expect(Link("Page", target: PathTestPage()).markupString() == #"<a href="/path-test-page/">Page</a>"#)
        #expect(Link(Self.article(path: "/story")).markupString() == #"<a href="/story/">Story</a>"#)
        #expect(Image("/images/a.png", description: "A").markupString() == #"<img src="/images/a.png" alt="A" />"#)
    }

    // MARK: - Links on a subsite

    @Test("On a subsite, a link to a page, an article or a tag of the site includes the subsite's path",
          .publishingContext(.subsite))
    func subsiteLinksToOwnPages() throws {
        #expect(Link("Page", target: PathTestPage()).markupString()
            == #"<a href="/subsite/path-test-page/">Page</a>"#)
        #expect(Link(Self.article(path: "/story")).markupString() == #"<a href="/subsite/story/">Story</a>"#)
        #expect(Link("Read", target: Self.article(path: "/story")).markupString()
            == #"<a href="/subsite/story/">Read</a>"#)
        #expect(Link(target: Self.article(path: "/story")) { "Read" }.markupString()
            == #"<a href="/subsite/story/">Read</a>"#)

        var tagged = Self.article(path: "/story")
        tagged.metadata["tags"] = "swift"
        let tagLinks = try #require(tagged.tagLinks(style: .plain))
        #expect(tagLinks.map { $0.markupString() } == [#"<a rel="tag" href="/subsite/tags/swift/">swift</a>"#])
    }

    @Test("On a subsite, a site path includes the subsite's path", .publishingContext(.subsite))
    func subsiteSitePath() {
        #expect(Link("Home", sitePath: "/").markupString() == #"<a href="/subsite/">Home</a>"#)
        #expect(Link("About", sitePath: "/about").markupString() == #"<a href="/subsite/about/">About</a>"#)
        #expect(Link(sitePath: "/about") { "About" }.markupString() == #"<a href="/subsite/about/">About</a>"#)
        #expect(Link("File", sitePath: "/files/a.pdf").markupString() == #"<a href="/subsite/files/a.pdf">File</a>"#)
    }

    @Test("On a subsite, a string target is written as authored", .publishingContext(.subsite), arguments: [
        ("/", "/"),
        ("/about", "/about/"),
        ("https://example.org/a", "https://example.org/a"),
        ("//cdn.example.org/a", "//cdn.example.org/a"),
        ("#section", "#section"),
        ("mailto:me@example.org", "mailto:me@example.org"),
        ("tel:+15551234", "tel:+15551234")
    ])
    func subsiteStringTargets(target: String, expected: String) {
        #expect(Link("x", target: target).markupString() == "<a href=\"\(expected)\">x</a>")
    }

    @Test("A site path that is not a path within the site is written as authored",
          .publishingContext(.subsite), arguments: [
        "https://example.org/a", "//cdn.example.org/a", "#section", "mailto:me@example.org", "tel:+15551234"
    ])
    func sitePathLeavesOtherAddressesAlone(target: String) {
        #expect(Link("x", sitePath: target).markupString() == "<a href=\"\(target)\">x</a>")
    }

    @Test("On a subsite, a link group to a page of the site includes the subsite's path",
          .publishingContext(.subsite))
    func subsiteLinkGroup() {
        #expect(LinkGroup(target: PathTestPage()) { Text("x") }.markupString()
            == #"<a href="/subsite/path-test-page/" class="link-plain d-inline-block"><p>x</p></a>"#)
        #expect(LinkGroup(target: Self.article(path: "/story")) { Text("x") }.markupString()
            == #"<a href="/subsite/story/" class="link-plain d-inline-block"><p>x</p></a>"#)
        #expect(LinkGroup(sitePath: "/about") { Text("x") }.markupString()
            == #"<a href="/subsite/about/" class="link-plain d-inline-block"><p>x</p></a>"#)
        #expect(LinkGroup(target: "/about") { Text("x") }.markupString() == #"<a href="/about/" class="link-plain d-inline-block"><p>x</p></a>"#)
    }

    // MARK: - Absolute addresses for metadata

    @Test("An address is made absolute against the site", arguments: [
        (TestPublishingSite.standard, "/images/a.png", "https://www.example.com/images/a.png"),
        (.standard, "images/a.png", "https://www.example.com/images/a.png"),
        (.standard, "https://cdn.example.org/a.png", "https://cdn.example.org/a.png"),
        (.standard, "//cdn.example.org/a.png", "https://cdn.example.org/a.png"),
        (.subsite, "/images/a.png", "https://www.example.com/subsite/images/a.png"),
        (.subsite, "images/a.png", "https://www.example.com/subsite/images/a.png"),
        (.relativePathsSubsite, "/images/a.png", "https://www.example.com/subsite/images/a.png"),
        (.standard, "", "")
    ])
    func absoluteAddress(site: TestPublishingSite, reference: String, expected: String) {
        #expect(site.site.absoluteAddress(for: reference) == expected)
    }

    @Test("A sharing image given as a path is written as an absolute address",
          arguments: [
        (TestPublishingSite.standard, "https://www.example.com/images/share.png"),
        (.subsite, "https://www.example.com/subsite/images/share.png"),
        (.relativePaths, "https://www.example.com/images/share.png")
    ])
    func sharingImageIsAbsolute(site: TestPublishingSite, expected: String) throws {
        let context = try Self.context(site)
        // Unwrapped on its own line: `image` is optional, so an inline `#require` there
        // has nothing left to require.
        let image: URL = try #require(URL(string: "/images/share.png"))
        var environment = EnvironmentValues()
        environment.page = PageMetadata(
            title: "T",
            description: "",
            url: site.site.url.appending(path: "about"),
            image: image)

        let tags = context.withEnvironment(environment) {
            MetaTag.socialSharingTags().map { $0.markupString() }
        }

        #expect(tags.contains("<meta property=\"og:image\" content=\"\(expected)\" />"))
        #expect(tags.contains("<meta name=\"twitter:image\" content=\"\(expected)\" />"))
        // Already absolute before this change, and pinned so it stays that way.
        #expect(tags.contains("<meta property=\"og:url\" content=\"\(site.site.url.absoluteString)/about\" />"))
    }

    @Test("A sharing image that is already absolute is written as authored", .publishingContext())
    func absoluteSharingImageIsUnchanged() throws {
        let image: URL = try #require(URL(string: "https://cdn.example.org/share.png?v=2"))
        var environment = EnvironmentValues()
        environment.page = PageMetadata(
            title: "T",
            description: "",
            url: try #require(URL(string: "https://www.example.com/about")),
            image: image)

        let tags = PublishingContext.shared.withEnvironment(environment) {
            MetaTag.socialSharingTags().map { $0.markupString() }
        }

        #expect(tags.contains(#"<meta property="og:image" content="https://cdn.example.org/share.png?v=2" />"#))
    }

    @Test("The canonical link is absolute, on a subsite and with relative paths too", arguments: [
        (TestPublishingSite.standard, "https://www.example.com/about"),
        (.subsite, "https://www.example.com/subsite/about"),
        (.relativePathsSubsite, "https://www.example.com/subsite/about")
    ])
    func canonicalLinkIsAbsolute(site: TestPublishingSite, expected: String) throws {
        let context = try Self.context(site)
        var environment = EnvironmentValues()
        environment.page = PageMetadata(title: "T", description: "", url: site.site.url.appending(path: "about"))

        let head = context.withEnvironment(environment) { Head().markupString() }
        #expect(head.contains("<link href=\"\(expected)\" rel=\"canonical\" />"))
    }

    @Test("Feed images are absolute addresses", arguments: [
        (TestPublishingSite.standard, "https://www.example.com/path/to/image.png"),
        (.subsite, "https://www.example.com/subsite/path/to/image.png")
    ])
    func feedImagesAreAbsolute(site: TestPublishingSite, expected: String) throws {
        let config = try #require(FeedConfiguration(
            mode: .descriptionOnly,
            contentCount: 20,
            image: .init(url: "path/to/image.png", width: 100, height: 100)))

        let rss = FeedGenerator(config: config, site: site.site, content: []).generateFeed()
        #expect(rss.contains("<image><url>\(expected)</url>"))

        let atom = AtomFeedGenerator(config: config, site: site.site, content: []).generateFeed()
        #expect(atom.contains("<icon>\(expected)</icon><logo>\(expected)</logo>"))

        let json = JSONFeedGenerator(config: config, site: site.site, content: []).generateFeed()
        #expect(json.contains("\"icon\" : \"\(expected)\""))
        #expect(json.contains("\"favicon\" : \"\(expected)\""))
    }

    @Test("Feed item links and sitemap locations are absolute on a subsite")
    func feedAndSitemapAddressesOnSubsite() throws {
        let site = TestSubsite()
        let config = try #require(FeedConfiguration(mode: .descriptionOnly, contentCount: 20))
        var article = Self.article(path: "/story")
        article.metadata["date"] = Date(timeIntervalSince1970: 1_700_000_000)

        let rss = FeedGenerator(config: config, site: site, content: [article]).generateFeed()
        #expect(rss.contains("<link>https://www.example.com/subsite/story</link>"))
        #expect(rss.contains("<guid isPermaLink=\"true\">https://www.example.com/subsite/story</guid>"))

        let atom = AtomFeedGenerator(config: config, site: site, content: [article]).generateFeed()
        #expect(atom.contains("<link href=\"https://www.example.com/subsite/story\" rel=\"alternate\"/>"))

        let json = JSONFeedGenerator(config: config, site: site, content: [article]).generateFeed()
        #expect(json.contains("\"url\" : \"https://www.example.com/subsite/story\""))

        let context = try PublishingContext.initialize(for: site, from: #filePath)
        context.addToSiteMap("/story", priority: 0.8)
        #expect(SiteMapGenerator(context: context).generateSiteMap()
            .contains("<loc>https://www.example.com/subsite/story/</loc>"))
    }

    @Test("An article's JSON-LD image is absolute", arguments: [
        (TestPublishingSite.standard, "/images/a.png", "https://www.example.com/images/a.png"),
        (.standard, "images/a.png", "https://www.example.com/images/a.png"),
        (.subsite, "/images/a.png", "https://www.example.com/subsite/images/a.png"),
        (.standard, "https://cdn.example.org/a.png", "https://cdn.example.org/a.png")
    ])
    func structuredDataImageIsAbsolute(site: TestPublishingSite, image: String, expected: String) throws {
        let context = try Self.context(site)
        var article = Self.article(path: "/story")
        article.metadata["image"] = image
        article.metadata["date"] = Date(timeIntervalSince1970: 1_700_000_000)

        var environment = EnvironmentValues()
        environment.article = article
        environment.page = PageMetadata(title: "Story", description: "", url: site.site.url.appending(path: "story"))

        let output = context.withEnvironment(environment) { StructuredData.article().markupString() }
        #expect(output.contains("\"image\" : \"\(expected)\""))
        #expect(output.contains("\"url\" : \"\(site.site.url.absoluteString)/story\""))
    }
}
