//
// LinkResolutionTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A page one level below the root.
private struct LinkAbout: StaticPage {
    var title = "About"
    var path = "/about"

    var body: some HTML {
        Text("About").id("team")
        Link("Home", sitePath: "/")
        Link("Setup", target: LinkSetup())
        Image("/images/photo.png", description: "A photo")
    }
}

/// A page two levels below the root.
private struct LinkSetup: StaticPage {
    var title = "Setup"
    var path = "/guides/setup"

    var body: some HTML {
        Text("Setup")
        Link("Home", sitePath: "/")
        Link("About", target: LinkAbout())
        Link("The team", sitePath: "/about#team")
        Image("/images/photo.png", description: "A photo")
    }
}

/// A home page that refers to everything a site can refer to.
private struct LinkHome: StaticPage {
    @Environment(\.articles) private var articles

    var title = "Home"

    var body: some HTML {
        Text("Home").id("top")

        Link("About", target: LinkAbout())
        Link("Setup", target: LinkSetup())
        Link("Home", sitePath: "/")
        Link("The team", sitePath: "/about#team")
        Link("A tab", sitePath: "/about?tab=2")
        Link("Tags", sitePath: "/tags")
        Link("Top", target: "#top")
        Link("Elsewhere", target: "https://other.example/page")
        Link("Write", target: "mailto:someone@example.com")

        Image("/images/photo.png", description: "A photo")
        Audio("/media/clip.mp3")
        Video("/media/clip.mp4")
        Script(file: "/js/site.js")

        ForEach(articles.all) { article in
            Section {
                Link(article)
                ForEach(article.tagLinks() ?? []) { link in link }
            }
        }
    }
}

private struct LinkArticlePage: ArticlePage {
    var body: some HTML {
        Text(article.title).font(.title1)
        Text(article.text)
        Link("Home", sitePath: "/")
        ForEach(article.tagLinks() ?? []) { link in link }
    }
}

private struct LinkTagPage: TagPage {
    var body: some HTML {
        Text(tag.name)
        ForEach(tag.articles) { article in
            Link(article)
        }
    }
}

private struct LinkErrorPage: ErrorPage {
    var title = "Not found"

    var body: some HTML {
        Text(error.description)
        Link("Home", sitePath: "/")
    }
}

/// A layout with a head, a navigation bar and the feed links, as most sites have.
private struct LinkLayout: Layout {
    var body: some Document {
        Head()

        Body {
            NavigationBar(logo: "Site", items: {
                Link("About", target: LinkAbout())
                Dropdown("More") {
                    Link("Setup", target: LinkSetup())
                }
            })

            content

            FeedLink()
        }
    }
}

/// One site, published at whatever address and in whichever path mode a test asks for.
private struct LinkSite: Site {
    var name = "Links"
    var url: URL
    var useRelativePaths: Bool

    var homePage = LinkHome()
    var layout = LinkLayout()
    var tagPage = LinkTagPage()
    var errorPage = LinkErrorPage()
    var favicon: URL? { URL(static: "/images/favicon.png") }
    var builtInIconsEnabled: BootstrapOptions { .localBootstrap }

    var staticPages: [any StaticPage] {
        LinkAbout()
        LinkSetup()
    }

    var articlePages: [any ArticlePage] {
        LinkArticlePage()
    }

    var feedConfiguration: FeedConfiguration? {
        FeedConfiguration(mode: .full, contentCount: 20, formats: [.rss, .atom, .json])
    }
}

/// Tests that publish a small site and follow every reference in it.
@Suite("Link Resolution Tests")
struct LinkResolutionTests {
    /// Creates a source directory with two tagged articles and the files the pages refer to.
    /// - Parameters:
    ///   - root: The directory to create the source in.
    ///   - rootRelativeMarkdown: Whether the first article links to the home page and
    ///   shows an image by paths from the root, which only a relative-path site rewrites.
    private func makeSource(in root: URL, rootRelativeMarkdown: Bool) throws -> URL {
        let source = root.appending(path: "Source")
        let content = source.appending(path: "Content/posts")
        try FileManager.default.createDirectory(at: content, withIntermediateDirectories: true)

        try """
        ---
        date: 2024-03-05 10:00
        tags: swift, web
        ---
        # First post

        Some text\(rootRelativeMarkdown ? ", [a link home](/), [one to a page](/about) and ![a photo](/images/photo.png)" : "").
        """.write(to: content.appending(path: "first.md"), atomically: true, encoding: .utf8)

        try """
        ---
        date: 2024-03-06 10:00
        tags: swift
        ---
        # Second post

        More text.
        """.write(to: content.appending(path: "second.md"), atomically: true, encoding: .utf8)

        let assets = [
            "images/photo.png", "images/photo@2x.png", "images/favicon.png",
            "media/clip.mp3", "media/clip.mp4", "js/site.js"
        ]

        for asset in assets {
            let file = source.appending(path: "Assets").appending(path: asset)
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("x".utf8).write(to: file)
        }

        return source
    }

    /// Publishes the site into a temporary directory and hands the build directory to a check.
    private func withPublishedSite(
        at address: String,
        useRelativePaths: Bool,
        check: (URL) throws -> Void
    ) async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-links-\(UUID().uuidString)")
        defer {
            do {
                try FileManager.default.removeItem(at: root)
            } catch {
                Issue.record("Could not remove temporary site: \(error)")
            }
        }

        let source = try makeSource(in: root, rootRelativeMarkdown: useRelativePaths)
        let build = root.appending(path: "Build")
        var site = LinkSite(url: try #require(URL(string: address)), useRelativePaths: useRelativePaths)

        try await site.publish(
            sourceDirectory: source,
            buildDirectory: build,
            logOptions: .standard,
            output: PublishingOutput { _ in }
        )

        try check(build)
    }

    /// The pages every shape of the site is expected to write.
    private static let expectedPages = [
        "404.html", "about/index.html", "guides/setup/index.html", "index.html",
        "posts/first/index.html", "posts/second/index.html",
        "tags/index.html", "tags/swift/index.html", "tags/web/index.html"
    ]

    @Test("Every reference in a relative-path site opens from disk")
    func relativeSiteOpensFromDisk() async throws {
        try await withPublishedSite(at: "https://www.example.com", useRelativePaths: true) { build in
            #expect(try LinkResolution.pages(in: build.resolvingSymlinksInPath()) == Self.expectedPages)
            #expect(try LinkResolution.referenceCount(in: build) > 100)
            let broken = try LinkResolution.brokenReferences(in: build, openedFrom: .disk)
            #expect(broken == [], "\(broken.map(\.description).joined(separator: "\n"))")
        }
    }

    @Test("Every reference in a relative-path site published for a subdirectory opens from disk")
    func relativeSubsiteOpensFromDisk() async throws {
        try await withPublishedSite(at: "https://www.example.com/docs", useRelativePaths: true) { build in
            #expect(try LinkResolution.pages(in: build.resolvingSymlinksInPath()) == Self.expectedPages)
            let broken = try LinkResolution.brokenReferences(in: build, openedFrom: .disk)
            #expect(broken == [], "\(broken.map(\.description).joined(separator: "\n"))")
        }
    }

    @Test("Every reference in a site at the root of its host resolves on a server")
    func rootSiteResolves() async throws {
        let address = "https://www.example.com"
        try await withPublishedSite(at: address, useRelativePaths: false) { build in
            #expect(try LinkResolution.pages(in: build.resolvingSymlinksInPath()) == Self.expectedPages)
            #expect(try LinkResolution.referenceCount(in: build) > 100)
            let site = try #require(URL(string: address))
            let broken = try LinkResolution.brokenReferences(in: build, openedFrom: .server(site))
            #expect(broken == [], "\(broken.map(\.description).joined(separator: "\n"))")
        }
    }

    @Test("Every reference in a site deployed in a subdirectory resolves within it")
    func subsiteResolves() async throws {
        let address = "https://www.example.com/docs"
        try await withPublishedSite(at: address, useRelativePaths: false) { build in
            #expect(try LinkResolution.pages(in: build.resolvingSymlinksInPath()) == Self.expectedPages)
            #expect(try LinkResolution.referenceCount(in: build) > 100)
            let site = try #require(URL(string: address))
            let broken = try LinkResolution.brokenReferences(in: build, openedFrom: .server(site))
            #expect(broken == [], "\(broken.map(\.description).joined(separator: "\n"))")
        }
    }
}

/// Tests of the checker itself, against a hand-written site with known faults: a check
/// that cannot fail proves nothing about the sites it passes.
@Suite("Link Resolution Checker Tests")
struct LinkResolutionCheckerTests {
    /// Writes a small site by hand and hands its directory to a check.
    private func withHandWrittenSite(_ pages: [String: String], check: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-checker-\(UUID().uuidString)")
        defer {
            do {
                try FileManager.default.removeItem(at: root)
            } catch {
                Issue.record("Could not remove temporary site: \(error)")
            }
        }

        for (path, contents) in pages {
            let file = root.appending(path: path)
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try contents.write(to: file, atomically: true, encoding: .utf8)
        }

        try check(root)
    }

    private static let diskSite = [
        "index.html": """
        <a href="about/index.html">ok</a> <a href="about/">directory</a> <a href="/about/index.html">root</a>
        <a href="missing.html">missing</a> <a href="#top">fragment</a> <a href="https://example.org/">other</a>
        <a href="mailto:a@example.org">mail</a> <img src="images/a%20b.png?v=1&amp;w=2" srcset="images/c.png 2x, images/d.png 3x">
        <a href="">empty</a>
        """,
        "about/index.html": #"<a href="../index.html#top">ok</a> <a href="../">directory</a>"#,
        "images/a b.png": "x",
        "images/c.png": "x"
    ]

    @Test("From disk, a reference must be relative and must name a file that exists")
    func diskFaults() throws {
        try withHandWrittenSite(Self.diskSite) { root in
            let broken = try LinkResolution.brokenReferences(in: root, openedFrom: .disk)
            #expect(broken.map(\.description) == [
                "about/index.html: ../ – is not a file; file:// opens nothing for it",
                "index.html: about/ – is not a file; file:// opens nothing for it",
                "index.html: /about/index.html – starts at the root of the disk",
                "index.html: missing.html – is not a file; file:// opens nothing for it",
                "index.html: images/d.png – is not a file; file:// opens nothing for it",
                "index.html:  – is empty"
            ])
            #expect(try LinkResolution.referenceCount(in: root) == 13)
        }
    }

    @Test("On a server, a path must lie within the site and lead to a file or a directory's index")
    func serverFaults() throws {
        let pages = [
            "index.html": """
            <a href="/docs/about/">ok</a> <a href="/docs/about">ok without slash</a> <a href="/docs/">home</a>
            <a href="/about/">outside</a> <a href="/docs/missing/">missing</a> <a href="/docsabout/">not the prefix</a>
            <a href="https://www.example.com/docs/about">own address</a>
            <a href="https://www.example.com/docs/gone">own address, missing</a>
            <a href="https://www.example.com/elsewhere">same host, outside</a>
            <a href="about/">relative</a> <a href="//cdn.example.org/a.js">protocol-relative</a>
            """,
            "about/index.html": #"<a href="../">home</a> <a href="../nothing/">missing</a>"#
        ]

        try withHandWrittenSite(pages) { root in
            let site = try #require(URL(string: "https://www.example.com/docs"))
            let broken = try LinkResolution.brokenReferences(in: root, openedFrom: .server(site))
            #expect(broken.map(\.description) == [
                "about/index.html: ../nothing/ – is not a file or a directory with an index.html",
                "index.html: /about/ – is outside the site, which is served under '/docs'",
                "index.html: /docs/missing/ – is not a file or a directory with an index.html",
                "index.html: /docsabout/ – is outside the site, which is served under '/docs'",
                "index.html: https://www.example.com/docs/gone – is not a file or a directory with an index.html"
            ])
        }
    }

    @Test("A site at the root of its host has no prefix to stay within")
    func rootServer() throws {
        let pages = [
            "index.html": #"<a href="/about/">ok</a> <a href="/">home</a> <a href="/gone">missing</a>"#,
            "about/index.html": #"<a href="https://www.example.com/">home</a>"#
        ]

        try withHandWrittenSite(pages) { root in
            let site = try #require(URL(string: "https://www.example.com"))
            let broken = try LinkResolution.brokenReferences(in: root, openedFrom: .server(site))
            #expect(broken.map(\.description) == [
                "index.html: /gone – is not a file or a directory with an index.html"
            ])
        }
    }
}
