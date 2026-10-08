//
// RobotsGenerator.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Writes a site's robots.txt in the format of the Robots Exclusion Protocol (RFC 9309).
struct RobotsGenerator {
    var site: any Site

    /// The robots.txt for the site: one group for each of its disallow rules, then a group
    /// allowing every other robot everywhere, then the address of the sitemap.
    ///
    /// The closing `User-agent: *` group is left out when one of the site's own rules is
    /// for `*`. A crawler merges groups that name the same user agent, and when an `Allow`
    /// and a `Disallow` match a path equally well the `Allow` wins, so adding `Allow: /`
    /// would cancel a rule that keeps every robot out of the whole site.
    func generateRobots() -> String {
        let rules = site.robotsConfiguration.disallowRules

        var groups = rules.map { rule in
            let lines = ["User-agent: \(Self.singleLine(rule.name))"]
                + rule.paths.map { "Disallow: \(Self.pathPattern($0))" }
            return lines.joined(separator: "\n") + "\n"
        }

        if !rules.contains(where: { Self.singleLine($0.name) == "*" }) {
            groups.append("User-agent: *\nAllow: /\n")
        }

        return groups.map { "\($0)\n" }.joined() + "Sitemap: \(sitemapAddress)"
    }

    /// The absolute address of the site's sitemap, which is what a `Sitemap` line requires.
    private var sitemapAddress: String {
        var base = site.url.absoluteString
        while base.hasSuffix("/") {
            base.removeLast()
        }
        return "\(base)/sitemap.xml"
    }

    /// A value for one line of the file: with nothing that would start another line, and
    /// no space at either end.
    private static func singleLine(_ value: String) -> String {
        String(value.unicodeScalars.filter { !$0.properties.generalCategory.isLineOrControl })
            .trimmingPrefixAndSuffixSpaces()
    }

    /// A path pattern as RFC 9309 defines one, which always begins with `/`.
    ///
    /// A pattern is matched against the path of a URL from its first character, so one
    /// written without the leading slash – `private`, or a bare `*` – matches nothing.
    /// An empty pattern is left empty: `Disallow:` with no path disallows nothing.
    private static func pathPattern(_ path: String) -> String {
        let pattern = singleLine(path)
        guard !pattern.isEmpty, !pattern.hasPrefix("/") else { return pattern }
        return "/\(pattern)"
    }
}

private extension Unicode.GeneralCategory {
    /// Whether characters of this category end a line or are control characters.
    var isLineOrControl: Bool {
        self == .control || self == .lineSeparator || self == .paragraphSeparator
    }
}

private extension String {
    /// This string without the spaces and tabs at its start and end.
    func trimmingPrefixAndSuffixSpaces() -> String {
        var result = Substring(self)
        while let first = result.first, first == " " || first == "\t" {
            result.removeFirst()
        }
        while let last = result.last, last == " " || last == "\t" {
            result.removeLast()
        }
        return String(result)
    }
}
