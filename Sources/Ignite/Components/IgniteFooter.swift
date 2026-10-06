//
// IgniteFooter.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// Displays "Created in Swift with Ignite", with a link back to the Ignite project on GitHub.
/// Including this is definitely not required for your site, but it's most appreciated 🙌
public struct IgniteFooter: HTML {
    /// Creates a footer that credits Ignite.
    public init() {}

    /// A centered line of text reading "Created in Swift with Ignite", which links to the
    /// Ignite project on GitHub and has an extra-large top margin.
    public var body: some HTML {
        Text {
            "Created in Swift with "
            Link("Ignite", target: URL(static: "https://github.com/twostraws/Ignite"))
        }
        .horizontalAlignment(.center)
        .margin(.top, .xLarge)
    }
}
