//
// RobotsGenerator.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A test site with configurable robots rules.
private struct RobotsTestSite: Site {
    var name = "My Test Site"
    var url = URL(static: "https://www.example.com")
    var homePage = TestPage()
    var layout = EmptyLayout()
    var robotsConfiguration: TestRobotsConfig

    init(rules: [DisallowRule] = []) {
        self.robotsConfiguration = TestRobotsConfig(disallowRules: rules)
    }
}

private struct TestRobotsConfig: RobotsConfiguration {
    var disallowRules: [DisallowRule]
}

/// Tests for the `RobotsGenerator` output formatting.
@Suite("RobotsGenerator Tests")
struct RobotsGeneratorTests {
    @Test("Default configuration produces standard robots.txt", .publishingContext())
    func defaultConfiguration() {
        let site = RobotsTestSite()
        let generator = RobotsGenerator(site: site)
        let output = generator.generateRobots()

        #expect(output == """
        User-agent: *
        Allow: /

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("A rule with no paths keeps its robot out of the whole site", .publishingContext())
    func singleDisallowRule() {
        let site = RobotsTestSite(rules: [
            DisallowRule(name: "BadBot")
        ])
        let generator = RobotsGenerator(site: site)
        let output = generator.generateRobots()

        #expect(output == """
        User-agent: BadBot
        Disallow: /

        User-agent: *
        Allow: /

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("Disallow rule with specific paths", .publishingContext())
    func disallowRuleWithPaths() {
        let site = RobotsTestSite(rules: [
            DisallowRule(name: "Googlebot", paths: ["/private", "/admin"])
        ])
        let generator = RobotsGenerator(site: site)
        let output = generator.generateRobots()

        #expect(output.contains("User-agent: Googlebot"))
        #expect(output.contains("Disallow: /private"))
        #expect(output.contains("Disallow: /admin"))
    }

    @Test("Multiple disallow rules are all included", .publishingContext())
    func multipleDisallowRules() {
        let site = RobotsTestSite(rules: [
            DisallowRule(name: "BadBot"),
            DisallowRule(name: "AnotherBot", paths: ["/secret"])
        ])
        let generator = RobotsGenerator(site: site)
        let output = generator.generateRobots()

        #expect(output.contains("User-agent: BadBot"))
        #expect(output.contains("User-agent: AnotherBot"))
        #expect(output.contains("Disallow: /secret"))
    }

    @Test("Known robot disallow rule uses correct name", .publishingContext())
    func knownRobotDisallowRule() {
        let site = RobotsTestSite(rules: [
            DisallowRule(robot: .chatGPT)
        ])
        let generator = RobotsGenerator(site: site)
        let output = generator.generateRobots()

        #expect(output.contains("User-agent: \(KnownRobot.chatGPT.rawValue)"))
    }

    @Test("Rules with paths are written exactly as before", .publishingContext())
    func rulesWithPathsExactOutput() {
        let site = RobotsTestSite(rules: [
            DisallowRule(name: "Googlebot", paths: ["/private", "/admin/"]),
            DisallowRule(robot: .bing, paths: ["/drafts"])
        ])

        #expect(RobotsGenerator(site: site).generateRobots() == """
        User-agent: Googlebot
        Disallow: /private
        Disallow: /admin/

        User-agent: bingbot
        Disallow: /drafts

        User-agent: *
        Allow: /

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("A known robot kept out of the whole site is disallowed from /", .publishingContext())
    func knownRobotWholeSite() {
        let site = RobotsTestSite(rules: [DisallowRule(robot: .chatGPT)])

        #expect(RobotsGenerator(site: site).generateRobots() == """
        User-agent: GPTBot
        Disallow: /

        User-agent: *
        Allow: /

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("A path is always written starting from the root", .publishingContext(), arguments: zip(
        ["private", "admin/area", "*", "*.pdf$", "/ok", " /spaced ", "/a\n/b"],
        ["/private", "/admin/area", "/*", "/*.pdf$", "/ok", "/spaced", "/a/b"]))
    func pathsStartAtRoot(path: String, expected: String) {
        let site = RobotsTestSite(rules: [DisallowRule(name: "BadBot", paths: [path])])

        #expect(RobotsGenerator(site: site).generateRobots() == """
        User-agent: BadBot
        Disallow: \(expected)

        User-agent: *
        Allow: /

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("A rule with an empty list of paths disallows nothing", .publishingContext())
    func emptyPathsDisallowNothing() {
        let site = RobotsTestSite(rules: [DisallowRule(name: "BadBot", paths: [])])

        #expect(RobotsGenerator(site: site).generateRobots() == """
        User-agent: BadBot

        User-agent: *
        Allow: /

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("A rule for every robot is not contradicted by the default group", .publishingContext())
    func wildcardRuleReplacesDefaultGroup() {
        let site = RobotsTestSite(rules: [
            DisallowRule(name: "GPTBot"),
            DisallowRule(name: "*", paths: ["/private"])
        ])

        #expect(RobotsGenerator(site: site).generateRobots() == """
        User-agent: GPTBot
        Disallow: /

        User-agent: *
        Disallow: /private

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("Keeping every robot out of the whole site is not undone by Allow: /", .publishingContext())
    func wildcardWholeSite() {
        let site = RobotsTestSite(rules: [DisallowRule(name: "*")])

        #expect(RobotsGenerator(site: site).generateRobots() == """
        User-agent: *
        Disallow: /

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("A robot name cannot start a new line of the file", .publishingContext())
    func robotNameIsOneLine() {
        let site = RobotsTestSite(rules: [DisallowRule(name: " BadBot\nAllow: /\r\n", paths: ["/x"])])

        #expect(RobotsGenerator(site: site).generateRobots() == """
        User-agent: BadBotAllow: /
        Disallow: /x

        User-agent: *
        Allow: /

        Sitemap: https://www.example.com/sitemap.xml
        """)
    }

    @Test("The sitemap address has one slash before sitemap.xml", .publishingContext(), arguments: zip(
        ["https://www.example.com", "https://www.example.com/", "https://www.example.com/subsite",
         "https://www.example.com/subsite/"],
        ["https://www.example.com/sitemap.xml", "https://www.example.com/sitemap.xml",
         "https://www.example.com/subsite/sitemap.xml", "https://www.example.com/subsite/sitemap.xml"]))
    func sitemapAddress(siteURL: String, expected: String) throws {
        var site = RobotsTestSite()
        site.url = try #require(URL(string: siteURL))

        #expect(RobotsGenerator(site: site).generateRobots() == """
        User-agent: *
        Allow: /

        Sitemap: \(expected)
        """)
    }
}
