//
//  DeterministicBuildTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A home page using every element that gives itself an ID.
private struct ReproducibleHome: StaticPage {
    var title = "Home"

    var body: some HTML {
        Text("Home")

        Accordion {
            Item("First") { Text("One") }
            Item("Second") { Text("Two") }
        }

        Accordion {
            Item("Third") { Text("Three") }
        }

        Carousel {
            Slide(background: "/images/a.png") { Text("A") }
            Slide(background: "/images/b.png") { Text("B") }
        }

        Table(filterTitle: "Filter") {
            Row { Column { "Cell" } }
        }

        Form {
            TextField("Name", prompt: "Your name")
            TextField("Email", prompt: "Your email")
            Button("Send").type(.submit)
        }

        SubscribeForm(.kit("abc123"))

        Text(placeholderLength: 30)
            .transition(.fadeIn, on: .appear)
    }
}

/// A second page, below the root, with generated IDs of its own.
private struct ReproducibleAbout: StaticPage {
    var title = "About"

    var body: some HTML {
        Accordion {
            Item("Only") { Text("One") }
        }

        Form {
            TextField("Search", prompt: "Search")
        }
    }
}

/// The page that shows an article.
private struct ReproducibleArticlePage: ArticlePage {
    var body: some HTML {
        Text(article.title).font(.title1)
        Text(article.text)
    }
}

/// The page that lists the articles with a tag.
private struct ReproducibleTagPage: TagPage {
    var body: some HTML {
        Text(tag.name)
        List {
            ForEach(tag.articles) { article in
                Link(article)
            }
        }
    }
}

/// A site with pages, articles, tags and every feed format.
private struct ReproducibleSite: Site {
    var name = "Reproducible"
    var url = URL(static: "https://www.example.com")
    var homePage = ReproducibleHome()
    var layout = EmptyLayout()

    var staticPages: [any StaticPage] {
        ReproducibleAbout()
    }

    var articlePages: [any ArticlePage] {
        ReproducibleArticlePage()
    }

    var tagPage = ReproducibleTagPage()

    var feedConfiguration: FeedConfiguration? {
        FeedConfiguration(mode: .full, contentCount: 20, formats: [.rss, .atom, .json])
    }
}

/// Tests that building the same site twice gives the same files.
@Suite("Deterministic Build Tests")
struct DeterministicBuildTests {
    /// Creates a source directory holding two dated articles.
    private func makeSource(in root: URL) throws -> URL {
        let source = root.appending(path: "Source")
        let content = source.appending(path: "Content/posts")
        try FileManager.default.createDirectory(at: content, withIntermediateDirectories: true)

        try """
        ---
        date: 2024-03-05 10:00
        tags: swift, web
        ---
        # First post

        Some *text* with `code`.
        """.write(to: content.appending(path: "first.md"), atomically: true, encoding: .utf8)

        try """
        ---
        date: 2024-03-05 10:00
        tags: swift
        ---
        # Second post

        More text.
        """.write(to: content.appending(path: "second.md"), atomically: true, encoding: .utf8)

        return source
    }

    /// Publishes the site and returns every file it wrote, by path relative to the build directory.
    private func publish(from source: URL, to build: URL) async throws -> [String: Data] {
        var site = ReproducibleSite()
        try await site.publish(
            sourceDirectory: source,
            buildDirectory: build,
            logOptions: .standard,
            output: PublishingOutput { _ in }
        )

        return try Self.files(in: build)
    }

    /// Reads every regular file beneath a directory.
    private static func files(in directory: URL) throws -> [String: Data] {
        let directoryPath = directory.resolvingSymlinksInPath().path
        let paths = try FileManager.default.subpathsOfDirectory(atPath: directoryPath)
        var files: [String: Data] = [:]

        for path in paths {
            let url = URL(fileURLWithPath: directoryPath).appending(path: path)
            guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
            files["/" + path] = try Data(contentsOf: url)
        }

        return files
    }

    @Test("Publishing an unchanged site twice writes identical files")
    func twoBuildsAreIdentical() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-repro-\(UUID().uuidString)")
        defer {
            do {
                try FileManager.default.removeItem(at: root)
            } catch {
                Issue.record("Could not remove temporary site: \(error)")
            }
        }

        let source = try makeSource(in: root)
        let first = try await publish(from: source, to: root.appending(path: "Build1"))
        let second = try await publish(from: source, to: root.appending(path: "Build2"))

        // The site really was built: pages, articles, tag pages, feeds, sitemap, robots, CSS.
        let expectedFiles = [
            "/index.html", "/reproducible-about/index.html", "/posts/first/index.html",
            "/posts/second/index.html", "/tags/index.html", "/tags/swift/index.html", "/tags/web/index.html",
            "/feed.rss", "/feed.atom", "/feed.json", "/sitemap.xml", "/robots.txt",
            "/css/ignite-core.min.css"
        ]
        #expect(Set(expectedFiles).isSubset(of: Set(first.keys)))

        #expect(first.keys.sorted() == second.keys.sorted())

        let differing = first.keys.sorted().filter { first[$0] != second[$0] }
        #expect(differing == [])
    }

    @Test("The elements that give themselves IDs are all on the page, with distinct IDs")
    func generatedIDsAreDistinctWithinAPage() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-repro-\(UUID().uuidString)")
        defer {
            do {
                try FileManager.default.removeItem(at: root)
            } catch {
                Issue.record("Could not remove temporary site: \(error)")
            }
        }

        let source = try makeSource(in: root)
        let files = try await publish(from: source, to: root.appending(path: "Build"))
        let home = String(decoding: try #require(files["/index.html"]), as: UTF8.self)

        let ids = home.matches(of: /\sid="([^"]+)"/).map { String($0.1) }
        // Elements that take their ID when they are created – carousels, fields, forms –
        // are numbered as the page's body is evaluated; accordions and tables take theirs
        // as they are rendered, which comes after.
        #expect(ids == [
            "ig-accordion-6", "ig-accordion-6-item-7", "ig-accordion-6-item-8",
            "ig-accordion-9", "ig-accordion-9-item-10",
            "ig-carousel-1",
            "ig-table-11",
            "ig-form-4", "ig-field-2", "ig-field-3",
            "ig-form-5"
        ])
        #expect(Set(ids).count == ids.count)

        // Numbering starts again on each page, so a change to one page leaves the others alone.
        let about = String(decoding: try #require(files["/reproducible-about/index.html"]), as: UTF8.self)
        #expect(about.matches(of: /\sid="([^"]+)"/).map { String($0.1) } == [
            "ig-accordion-3", "ig-accordion-3-item-4", "ig-form-2", "ig-field-1"
        ])
    }
}
