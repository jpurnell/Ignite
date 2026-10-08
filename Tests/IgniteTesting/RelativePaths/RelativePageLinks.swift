//
// RelativePageLinks.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A page used as a link target; its path is `/about`.
private struct RelativeLinkAbout: StaticPage {
    var title = "About"
    var path = "/about"
    var body: some HTML { Text("About") }
}

/// Tests that a relative-path site links to the file of a page, not to its directory.
///
/// A relative-path site is one that opens from a folder. `file://` does not open
/// `index.html` for a directory the way a web server does, so a link to `about/` leads
/// to a directory listing or to nothing.
@Suite("Relative Page Link Tests")
struct RelativePageLinkTests {
    private static func context(_ site: TestPublishingSite, pageAt path: String = "") throws -> PublishingContext {
        let context = try PublishingContext.initialize(for: site.site, from: #filePath)
        context.beginPage(at: path)
        return context
    }

    private static func href(_ link: Link, in context: PublishingContext) throws -> String {
        try #require(PublishingContext.withCurrent(context) { link.markupString() }.htmlAttribute(named: "href"))
    }

    @Test("From the home page, links name each page's file", arguments: [
        TestPublishingSite.relativePaths, .relativePathsSubsite
    ])
    func fromHomePage(site: TestPublishingSite) throws {
        let context = try Self.context(site)
        #expect(try Self.href(Link("About", target: RelativeLinkAbout()), in: context) == "about/index.html")
        #expect(try Self.href(Link("About", sitePath: "/about"), in: context) == "about/index.html")
        #expect(try Self.href(Link("About", sitePath: "/about/"), in: context) == "about/index.html")
        #expect(try Self.href(Link("About", target: "/about"), in: context) == "about/index.html")
        #expect(try Self.href(Link("About", target: "about"), in: context) == "about/index.html")
        #expect(try Self.href(Link("Deep", sitePath: "/guides/setup"), in: context) == "guides/setup/index.html")
        #expect(try Self.href(Link("Home", sitePath: "/"), in: context) == "index.html")
        #expect(try Self.href(Link("Home", target: "/"), in: context) == "index.html")
    }

    @Test("From a page below the root, links climb to the root and name the file", arguments: [
        ("about", "../"), ("guides/setup", "../../")
    ])
    func fromDeeperPage(page: String, climb: String) throws {
        let context = try Self.context(.relativePaths, pageAt: page)
        #expect(try Self.href(Link("About", target: RelativeLinkAbout()), in: context) == "\(climb)about/index.html")
        #expect(try Self.href(Link("Home", sitePath: "/"), in: context) == "\(climb)index.html")
    }

    @Test("A query or a fragment stays after the file name")
    func queryAndFragment() throws {
        let context = try Self.context(.relativePaths)
        #expect(try Self.href(Link("Team", sitePath: "/about#team"), in: context) == "about/index.html#team")
        #expect(try Self.href(Link("Tab", sitePath: "/about?tab=2"), in: context) == "about/index.html?tab=2")
        // A fragment of the home page, from the home page, is a place on this page.
        #expect(try Self.href(Link("Top", sitePath: "/#top"), in: context) == "#top")

        let deeper = try Self.context(.relativePaths, pageAt: "about")
        #expect(try Self.href(Link("Top", sitePath: "/#top"), in: deeper) == "../index.html#top")
    }

    @Test("A link that already names a file, or leads off the site, is unchanged", arguments: [
        ("/files/report.pdf", "files/report.pdf"),
        ("/about/index.html", "about/index.html"),
        ("#top", "#top"),
        ("?page=2", "?page=2"),
        ("https://example.org/about", "https://example.org/about"),
        ("https://example.org/about/", "https://example.org/about/"),
        ("//cdn.example.org/a", "//cdn.example.org/a"),
        ("mailto:someone@example.org", "mailto:someone@example.org"),
        ("tel:+15551234", "tel:+15551234")
    ])
    func unchangedTargets(target: String, expected: String) throws {
        let context = try Self.context(.relativePaths)
        #expect(try Self.href(Link("Link", target: target), in: context) == expected)
    }

    @Test("A site that writes absolute paths links to the directory, as before", arguments: [
        (TestPublishingSite.standard, ""), (.subsite, "/subsite")
    ])
    func absoluteSitesUnchanged(site: TestPublishingSite, prefix: String) throws {
        let context = try Self.context(site, pageAt: "guides/setup")
        #expect(try Self.href(Link("About", target: RelativeLinkAbout()), in: context) == "\(prefix)/about/")
        #expect(try Self.href(Link("About", sitePath: "/about#team"), in: context) == "\(prefix)/about/#team")
        #expect(try Self.href(Link("Home", sitePath: "/"), in: context) == "\(prefix)/")
        #expect(try Self.href(Link("About", target: "/about"), in: context) == "/about/")
        #expect(try Self.href(Link("Home", target: "/"), in: context) == "/")
    }

    // MARK: - Links Ignite writes itself

    @Test("The logo of a navigation bar leads to the home page of the site", arguments: [
        (TestPublishingSite.standard, "/"), (.subsite, "/subsite/"),
        (.relativePaths, "../index.html"), (.relativePathsSubsite, "../index.html")
    ])
    func navigationBarLogo(site: TestPublishingSite, expected: String) throws {
        let context = try Self.context(site, pageAt: "about")
        let output = PublishingContext.withCurrent(context) { NavigationBar(logo: "Site").markupString() }
        #expect(output.contains(
            #"<a href="\#(expected)" class="d-inline-flex align-items-center navbar-brand">Site</a>"#))
    }

    @Test("A logo that is already a link keeps its own target")
    func navigationBarLogoLink() throws {
        let context = try Self.context(.subsite)
        let output = PublishingContext.withCurrent(context) {
            NavigationBar(logo: Link("Site", target: "https://example.org")).markupString()
        }
        #expect(output.contains(#"<a href="https://example.org" class="d-inline-flex align-items-center navbar-brand">"#))
    }

    // MARK: - Markdown

    @Test("Markdown links and images from the root are made relative to the page showing them")
    func markdownOnRelativeSite() throws {
        let context = try Self.context(.relativePaths, pageAt: "posts/first")
        var article = Article()
        article.text = """
        <p><a href="/">Home</a> <a href="/about">About</a> <a href="/about#team">Team</a> \
        <a href="/files/a.pdf?v=1&amp;w=2">File</a> <img src="/images/a.png" alt="A" class="img-fluid"> \
        <a href="https://example.org/">Out</a> <a href="//cdn.example.org/a">CDN</a> <a href="#top">Top</a> \
        <a href="notes">Notes</a></p>
        """

        #expect(context.resolvedForCurrentPage(article).text == """
        <p><a href="../../index.html">Home</a> <a href="../../about/index.html">About</a> \
        <a href="../../about/index.html#team">Team</a> \
        <a href="../../files/a.pdf?v=1&amp;w=2">File</a> <img src="../../images/a.png" alt="A" class="img-fluid"> \
        <a href="https://example.org/">Out</a> <a href="//cdn.example.org/a">CDN</a> <a href="#top">Top</a> \
        <a href="notes">Notes</a></p>
        """)
    }

    @Test("On a site that writes absolute paths, Markdown is shown as it was written", arguments: [
        TestPublishingSite.standard, .subsite
    ])
    func markdownOnAbsoluteSite(site: TestPublishingSite) throws {
        let context = try Self.context(site, pageAt: "posts/first")
        var article = Article()
        article.text = #"<p><a href="/">Home</a> <a href="/about">About</a> <img src="/images/a.png" alt="A"></p>"#
        #expect(context.resolvedForCurrentPage(article).text == article.text)
    }
}
