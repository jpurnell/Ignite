//
// Page.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// A single flattened page from any source – static or dynamic – ready to be
/// passed through a theme.
public struct PageMetadata: Sendable {
    /// The title of the page.
    private(set) public var title: String
    /// A plain-text description of the page.
    private(set) public var description: String
    /// The absolute URL of the page: the URL of the site followed by the path of the page.
    private(set) public var url: URL
    /// The image that represents the page when it is shared, if it has one.
    private(set) public var image: URL?
}

extension PageMetadata {
    /// Creates an empty page for use as a default value
    static let empty = PageMetadata(
        title: "",
        description: "",
        url: .blankPlaceholder
    )
}
