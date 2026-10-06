//
// DarkOnlyThemeTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A theme whose accent color appears nowhere in Ignite's or Bootstrap's defaults,
/// so finding it in the generated CSS proves this theme's variables were written.
private struct MarkerTheme: Theme {
    var colorScheme: ColorScheme
    var accent: Color { Color(red: 1, green: 2, blue: 3) }
}

/// A site with one page and exactly one theme, in the light or the dark slot.
private struct SingleThemeSite: Site {
    var name = "Single Theme"
    var url = URL(static: "https://www.example.com")
    var homePage = SingleThemeHome()
    var layout = EmptyLayout()
    var feedConfiguration: FeedConfiguration? { nil }
    var lightTheme: (any Theme)?
    var darkTheme: (any Theme)?
}

/// A page with no content that could add CSS of its own.
private struct SingleThemeHome: StaticPage {
    var title = "Home"

    var body: some HTML {
        Text("Home")
    }
}

/// Tests for the theme CSS of a site that has only a dark theme.
@Suite("Dark-Only Theme Tests")
struct DarkOnlyThemeTests {
    /// Publishes a site to a temporary directory and returns its `ignite-core.min.css`.
    private func publishedCoreCSS(for site: SingleThemeSite) async throws -> String {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-theme-\(UUID().uuidString)")
        let source = root.appending(path: "Source")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: root)
            } catch {
                Issue.record("Could not remove temporary site: \(error)")
            }
        }

        var site = site
        try await site.publish(
            sourceDirectory: source,
            buildDirectory: root.appending(path: "Build"),
            logOptions: .standard,
            output: PublishingOutput { _ in }
        )

        return try String(
            contentsOf: root.appending(path: "Build/css/ignite-core.min.css"),
            encoding: .utf8
        )
    }

    /// The number of times `needle` occurs in `haystack`.
    private func occurrences(of needle: String, in haystack: String) -> Int {
        haystack.components(separatedBy: needle).count - 1
    }

    @Test("A dark-only site writes its theme variables into :root")
    func darkOnlySiteWritesRootVariables() async throws {
        let theme = MarkerTheme(colorScheme: .dark)
        let css = try await publishedCoreCSS(for: SingleThemeSite(lightTheme: nil, darkTheme: theme))

        let context = try PublishingContext.initialize(for: TestSite(), from: #filePath)
        let rootRuleset = context.rootStyles(for: theme).description

        #expect(rootRuleset.contains("--bs-primary: rgb(1 2 3 / 100%)"))
        #expect(occurrences(of: rootRuleset, in: css) == 1)
        #expect(occurrences(of: "--bs-primary: rgb(1 2 3 / 100%)", in: css) == 1)
    }

    @Test("A dark-only site gets the same theme CSS as a light-only site with the same theme")
    func darkOnlyMatchesLightOnly() async throws {
        let theme = MarkerTheme(colorScheme: .dark)
        let darkOnly = try await publishedCoreCSS(for: SingleThemeSite(lightTheme: nil, darkTheme: theme))
        let lightOnly = try await publishedCoreCSS(for: SingleThemeSite(lightTheme: theme, darkTheme: nil))

        #expect(darkOnly == lightOnly)
    }
}
