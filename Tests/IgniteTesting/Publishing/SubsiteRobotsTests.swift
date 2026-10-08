//
//  SubsiteRobotsTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A page with nothing on it but text.
private struct RobotsHome: StaticPage {
    var title = "Home"
    var body: some HTML { Text("Home") }
}

/// A site with one page, published wherever `url` says.
private struct RobotsSite: Site {
    var name = "Robots"
    var url: URL
    var homePage = RobotsHome()
    var layout = EmptyLayout()
    var feedConfiguration: FeedConfiguration? { nil }
}

/// Tests that robots.txt is only written where a crawler will read it: at the root of a host.
@Suite("Subsite Robots Tests")
struct SubsiteRobotsTests {
    /// Publishes a site to a temporary directory.
    /// - Returns: The contents of `robots.txt` if one was written, whether `sitemap.xml`
    /// was written, and everything the build reported.
    private func publish(at address: String) async throws -> (robots: String?, hasSitemap: Bool, report: String) {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-robots-\(UUID().uuidString)")
        let source = root.appending(path: "Source")
        let build = root.appending(path: "Build")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: root)
            } catch {
                Issue.record("Could not remove temporary site: \(error)")
            }
        }

        let lines = LockedLines()
        var site = RobotsSite(url: try #require(URL(string: address)))
        try await site.publish(
            sourceDirectory: source,
            buildDirectory: build,
            logOptions: .standard,
            output: PublishingOutput { lines.append($0) }
        )

        let robotsURL = build.appending(path: "robots.txt")
        let robots = FileManager.default.fileExists(atPath: robotsURL.path)
            ? try String(contentsOf: robotsURL, encoding: .utf8)
            : nil
        let hasSitemap = FileManager.default.fileExists(atPath: build.appending(path: "sitemap.xml").path)
        return (robots, hasSitemap, lines.joined)
    }

    @Test("A site at the root of its host writes robots.txt as before", arguments: [
        "https://www.example.com", "https://www.example.com/"
    ])
    func rootSiteWritesRobots(address: String) async throws {
        let result = try await publish(at: address)

        #expect(result.robots == "User-agent: *\nAllow: /\n\nSitemap: https://www.example.com/sitemap.xml")
        #expect(result.hasSitemap)
        #expect(result.report.contains("robots.txt") == false)
    }

    @Test("A site published under a path writes no robots.txt and says what to do instead", arguments: [
        "https://www.example.com/subsite", "https://www.example.com/subsite/"
    ])
    func subsiteWritesNoRobots(address: String) async throws {
        let result = try await publish(at: address)

        #expect(result.robots == nil)
        // The sitemap is valid where it is: it lists pages under its own directory.
        #expect(result.hasSitemap)
        #expect(result.report.contains("""
        No robots.txt was written. Crawlers read robots.txt only at the root of a host, and this site is \
        published under /subsite, where the file would never be read. Add this site's rules to \
        https://www.example.com/robots.txt instead, with /subsite in front of each path, and add the line \
        "Sitemap: https://www.example.com/subsite/sitemap.xml" there so that crawlers find this site's sitemap.
        """))
    }
}

/// Collects what a publish reports, from whichever thread reports it.
// Justification: `chunks` is the only mutable state and every read or write of it holds `lock`.
private final class LockedLines: @unchecked Sendable {
    private let lock = NSLock()
    private var chunks = [String]()

    func append(_ text: String) {
        lock.lock()
        defer { lock.unlock() }
        chunks.append(text)
    }

    var joined: String {
        lock.lock()
        defer { lock.unlock() }
        return chunks.joined()
    }
}
