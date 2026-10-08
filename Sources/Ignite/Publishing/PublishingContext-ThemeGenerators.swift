//
// PublishingContext-ThemeGenerators.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension PublishingContext {
    /// Creates CSS rules for all themes and writes to themes.min.css
    func generateThemes(_ themes: [any Theme]) throws {
        guard !themes.isEmpty else { return }

        let rules = try generateThemeRules(themes)
            .map(\.description)
            .joined(separator: "\n\n")

        try writeThemeRules(rules, to: "css/ignite-core.min.css")
    }

    /// Writes CSS rules to a file
    private func writeThemeRules(_ rules: String, to path: String) throws {
        let cssPath = buildDirectory.appending(path: path)
        do {
            let existingContent = try String(contentsOf: cssPath, encoding: .utf8)
            let newContent = existingContent + "\n\n" + rules
            try newContent.write(to: cssPath, atomically: true, encoding: .utf8)
        } catch {
            throw PublishingError.failedToWriteFile(path)
        }
    }

    /// Generates CSS for all themes including font faces, colors, and typography settings, writing to themes.min.css.
    private func globalRulesets() throws -> String {
        guard let sourceURL = Bundle.module.url(forResource: "Resources/css/global-rules", withExtension: "css") else {
            throw PublishingError.missingSiteResource("css/global-rules.css")
        }

        do {
            let contents = try String(contentsOf: sourceURL)
            return contents
        } catch {
            throw PublishingError.failedToCopySiteResource("css/global-rules.css")
        }
    }

    /// Creates @font-face and @import rules for custom fonts in a theme.
    func fontRules(for fonts: some Collection<Font>) -> [String] {
        let systemFonts = Font.systemFonts + Font.monospaceFonts
        let declarations = fonts.compactMap { font -> [String]? in
            guard let family = font.name,
                  !family.isEmpty,
                  !systemFonts.contains(family)
            else { return nil }
            return font.sources.compactMap { source in
                generateFontRule(family: family, source: source)?.description
            }
        }

        return declarations.flatMap { $0 }
    }

    private func generateFontRule(family: String, source: FontSource) -> CustomStringConvertible? {
        if source.url.host()?.contains("fonts.googleapis.com") == true {
            return ImportRule(source.url)
        }

        return FontFaceRule(
            family: family,
            source: fontFileAddress(for: source.url),
            weight: source.weight.description,
            style: source.variant.rawValue
        )
    }

    /// The address a stylesheet uses for a font file.
    ///
    /// A font the site serves itself, given as a path from the root of the site, is
    /// prefixed with the site's path like every other asset, so a site deployed in a
    /// subdirectory finds it. Any other address is written as given. So is every address
    /// on a site that uses relative paths: a path in a stylesheet is resolved against the
    /// stylesheet rather than the page, so the page-relative form would point elsewhere.
    private func fontFileAddress(for url: URL) -> String {
        guard !site.useRelativePaths, url.scheme == nil, url.host() == nil else {
            return url.absoluteString
        }

        return assetPath(url.relativeString)
    }

    /// Creates CSS rules for light theme
    private func lightThemeRules(_ theme: any Theme, darkThemeID: String?) throws -> [String] {
        var rules: [CustomStringConvertible] = []
        rules.append(rootStyles(for: theme))
        rules.append(contentsOf: try baseThemeRules(theme))
        rules.append(contentsOf: themeOverrides(for: theme))
        return rules.map(\.description)
    }

    /// Creates CSS rules for dark theme
    private func darkThemeRules(_ theme: any Theme, lightThemeID: String?) throws -> [String] {
        var rules: [CustomStringConvertible] = []

        // If this is the only theme, use it as root theme
        if !site.supportsLightTheme, site.alternateThemes.isEmpty {
            rules.append(rootStyles(for: theme))
            rules.append(contentsOf: try baseThemeRules(theme))
            return rules.map(\.description)
        }

        // Add explicit dark theme override
        rules.append(
            Ruleset(.attribute(name: "data-bs-theme", value: theme.cssID)) {
                themeStyles(for: theme)
            }
        )

        return rules.map(\.description)
    }

    /// Collects all CSS rules for the themes
    private func generateThemeRules(_ themes: [any Theme]) throws -> [String] {
        guard site.supportsLightTheme || site.supportsDarkTheme else {
            throw PublishingError.missingDefaultTheme
        }

        var rules: OrderedSet<String> = []

        let themeFontRules: OrderedSet = OrderedSet(themes.flatMap { theme in
            let themeFonts = [theme.monospaceFont, theme.font, theme.headingFont]
            return fontRules(for: themeFonts)
        })

        rules.append(contentsOf: themeFontRules)

        let customFontRules = fontRules(for: cssManager.customFonts)
        rules.append(contentsOf: customFontRules)

        let (lightTheme, darkTheme) = configureDefaultThemes(site.lightTheme, site.darkTheme)

        if let lightTheme {
            rules.append(contentsOf: try lightThemeRules(lightTheme, darkThemeID: darkTheme?.cssID))
        }

        if let darkTheme {
            rules.append(contentsOf: try darkThemeRules(darkTheme, lightThemeID: lightTheme?.cssID))
        }

        for theme in site.alternateThemes {
            rules.append(
                Ruleset(.attribute(name: "data-bs-theme", value: theme.cssID)) {
                    themeStyles(for: theme)
                }.description
            )
        }

        return Array(rules)
    }

    /// Configures default light and dark themes, inheriting properties when needed
    private func configureDefaultThemes(_ light: (any Theme)?, _ dark: (any Theme)?)
    -> (light: (any Theme)?, dark: (any Theme)?
    ) {
        var lightTheme = light
        var darkTheme = dark

        if let dark = darkTheme as? DefaultDarkTheme, let lightTheme, !lightTheme.isDefaultLightTheme {
            darkTheme = dark.merging(lightTheme)
        }

        if let light = lightTheme as? DefaultLightTheme, let darkTheme, !darkTheme.isDefaultDarkTheme {
            lightTheme = light.merging(darkTheme)
        }

        return (lightTheme, darkTheme)
    }

    /// Creates base theme rules (for root theme)
    private func baseThemeRules(_ theme: any Theme) throws -> [String] {
        var rules: [CustomStringConvertible] = []
        rules.append(contentsOf: responsiveVariables(for: theme))
        rules.append(contentsOf: containerMediaQueries(for: theme))
        rules.append(try globalRulesets())
        return rules.map(\.description)
    }

    /// Creates theme override rulesets if needed
    private func themeOverrides(for theme: any Theme) -> [Ruleset] {
        var overrides: [Ruleset] = []

        if site.hasMultipleThemes {
            overrides.append(
                Ruleset(.attribute(name: "data-bs-theme", value: theme.cssID)) {
                    themeStyles(for: theme)
                }
            )
        }

        return overrides
    }

    /// Contains the various snap dimensions for different Bootstrap widths.
    private func containerMediaQueries(for theme: any Theme) -> [MediaQuery] {
        let breakpoints: [LengthUnit] = [
            theme.siteWidth.values[.small] ?? Bootstrap.smallContainer,
            theme.siteWidth.values[.medium] ?? Bootstrap.mediumContainer,
            theme.siteWidth.values[.large] ?? Bootstrap.largeContainer,
            theme.siteWidth.values[.xLarge] ?? Bootstrap.xLargeContainer,
            theme.siteWidth.values[.xxLarge] ?? Bootstrap.xxLargeContainer
        ]

        return breakpoints.map { minWidth in
            MediaQuery(.breakpoint(.custom(minWidth))) {
                Ruleset(.class("container")) {
                    InlineStyle(.maxWidth, value: "\(minWidth)")
                }
            }
        }
    }
}

private extension Site {
    var supportsLightTheme: Bool {
        lightTheme != nil
    }

    var supportsDarkTheme: Bool {
        darkTheme != nil
    }

    var hasMultipleThemes: Bool {
        (supportsLightTheme && supportsDarkTheme) ||
        !alternateThemes.isEmpty
    }
}

private extension Theme {
    var isDefaultLightTheme: Bool {
        self is DefaultLightTheme
    }

    var isDefaultDarkTheme: Bool {
        self is DefaultDarkTheme
    }
}
