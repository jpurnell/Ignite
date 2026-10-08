//
// FeedLink.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Displays links to your syndication feeds, if enabled.
/// Renders one link per configured feed format (RSS, Atom, JSON Feed).
public struct FeedLink: HTML {

    @Environment(\.builtInIconsEnabled) private var builtInIconsEnabled
    @Environment(\.feedConfiguration) private var feedConfig

    /// One centered line of text per feed format, each linking to that feed and preceded by
    /// an RSS icon when the site's built-in icons are enabled. This is empty when the site
    /// has no feed configuration.
    public var body: some HTML {
        if let feedConfig {
            let sortedFormats = feedConfig.formats.sorted { $0.rawValue < $1.rawValue }
            ForEach(sortedFormats) { format in
                Text {
                    if builtInIconsEnabled != .none {
                        Image(systemName: "rss-fill", description: "")
                            .foregroundStyle("#f26522")
                            .margin(.trailing, .px(10))
                    }

                    let path = feedConfig.paths[format]
                        ?? FeedConfiguration.defaultPaths[format]
                        ?? "/feed.\(format.rawValue)"
                    // The feed is a file of this site, so its path is taken from the site's
                    // root and not from the host's.
                    Link(format.linkTitle, sitePath: path)
                    EmptyInlineElement()
                }
                .horizontalAlignment(.center)
            }
        }
    }
}
