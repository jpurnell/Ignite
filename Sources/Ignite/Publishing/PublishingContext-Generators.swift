//
// PublishingContext-Generators.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension PublishingContext {
    /// Renders static pages and content pages, including the homepage.
    func generateContent() async throws {
        render(homePage: site.homePage)

        for page in site.staticPages {
            render(page)
        }

        for content in allContent {
            try render(content)
        }

        currentRenderingPath = nil

        await renderTagPages()
        await renderErrorPages()
        pageDirectoryDepth = 0
    }

    /// Generates a sitemap.xml file for this site.
    func generateSiteMap() throws {
        let generator = SiteMapGenerator(context: self)
        let siteMap = generator.generateSiteMap()

        let outputURL = buildDirectory.appending(path: "sitemap.xml")

        do {
            try siteMap.write(to: outputURL, atomically: true, encoding: .utf8)
        } catch {
            throw PublishingError.failedToCreateBuildFile(outputURL)
        }
    }

    /// Generates syndication feeds for this site in all enabled formats.
    public func generateFeed() {
        guard let feedConfig = site.feedConfiguration else { return }

        var filtered = allContent
        if let types = feedConfig.contentTypes {
            filtered = filtered.filter { types.contains($0.type) }
        }

        let content = filtered.sorted(
            by: \.date,
            order: .reverse
        )

        for format in feedConfig.formats {
            let output: String
            switch format {
            case .rss:
                output = FeedGenerator(config: feedConfig, site: site, content: content)
                    .generateFeed()
            case .atom:
                output = AtomFeedGenerator(config: feedConfig, site: site, content: content)
                    .generateFeed()
            case .json:
                output = JSONFeedGenerator(config: feedConfig, site: site, content: content)
                    .generateFeed()
            }

            let path = feedConfig.paths[format]
                ?? FeedConfiguration.defaultPaths[format]
                ?? "/feed.\(format.rawValue)"

            do {
                let destinationURL = buildDirectory.appending(path: path)
                try output.write(to: destinationURL, atomically: true, encoding: .utf8)
            } catch {
                let reason = error.localizedDescription
                logger.error("Failed to write feed at \(path, privacy: .public): \(reason, privacy: .public)")
                addError(.failedToWriteFeed)
            }
        }
    }

    /// Generates a robots.txt file for this site, if the site is somewhere a crawler
    /// will read one.
    ///
    /// The Robots Exclusion Protocol (RFC 9309) has a crawler fetch `/robots.txt` from the
    /// root of a host and nowhere else. A site published under a path –
    /// `https://example.com/docs` – would write its file to `/docs/robots.txt`, which no
    /// crawler requests, so its rules would look as if they were in force and do nothing.
    /// For such a site no file is written, and the build says where the rules have to go.
    /// The sitemap is still written: a sitemap may live in a subdirectory and describe
    /// the pages beneath it, but crawlers only learn of it from the host's robots.txt.
    public func generateRobots() {
        guard sitePathPrefix.isEmpty else {
            let hostRobots = hostRootAddress + "/robots.txt"
            let sitemap = hostRootAddress + sitePathPrefix + "/sitemap.xml"

            addWarning("""
            No robots.txt was written. Crawlers read robots.txt only at the root of a host, and this site is \
            published under \(sitePathPrefix), where the file would never be read. Add this site's rules to \
            \(hostRobots) instead, with \(sitePathPrefix) in front of each path, and add the line \
            "Sitemap: \(sitemap)" there so that crawlers find this site's sitemap.
            """)
            return
        }

        let generator = RobotsGenerator(site: site)
        let result = generator.generateRobots()

        do {
            let destinationURL = buildDirectory.appending(path: "robots.txt")
            try result.write(to: destinationURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Failed to write robots.txt: \(error.localizedDescription, privacy: .public)")
            addError(.failedToWriteFile("robots.txt"))
        }
    }

    /// The address of the root of the site's host: its scheme, host and port, with no path
    /// and no trailing slash.
    private var hostRootAddress: String {
        var address = site.url.absoluteString

        // Everything from the site's own path onward goes; what is left is the host.
        if let components = URLComponents(url: site.url, resolvingAgainstBaseURL: true) {
            var root = URLComponents()
            root.scheme = components.scheme
            root.host = components.host
            root.port = components.port
            address = root.string ?? address
        }

        while address.hasSuffix("/") {
            address.removeLast()
        }

        return address
    }

    /// Generates the CSS file containing all media query rules, including styles.
    func generateMediaQueryCSS() {
        logger.info("Generating CSS for custom styles.")
        if shouldLog(.notices) {
            output.line("Generating CSS for custom styles. This may take a moment...")
        }

        let mediaQueryCSS = cssManager.generateAllRules(themes: site.allThemes)
        let stylesCSS = styleManager.generateAllCSS(themes: site.allThemes)
        let combinedCSS = [mediaQueryCSS, stylesCSS]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        do {
            let igniteCoreDirectory = buildDirectory.appending(path: "css/ignite-core.min.css")
            let existingContent = try String(contentsOf: igniteCoreDirectory, encoding: .utf8)
            let newContent = existingContent + "\n\n" + combinedCSS
            try newContent.write(to: igniteCoreDirectory, atomically: true, encoding: .utf8)
        } catch {
            let reason = error.localizedDescription
            logger.error("Failed to append custom styles to ignite-core.min.css: \(reason, privacy: .public)")
            addError(.failedToWriteFile("css/ignite-core.min.css"))
        }
    }

    /// Generates animations for the site.
    func generateAnimations() {
        let animationsPath = buildDirectory.appending(path: "css/ignite-core.min.css")
        animationManager.write(to: animationsPath, reportingTo: self)
    }
}
