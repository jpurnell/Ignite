//
// Content.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Provides access to the Markdown articles of your site, usually through
/// `@Environment(\.articles)`.
public struct ArticleLoader: Sendable {
    /// Every article on the site.
    public var all: [Article]

    init(content: [Article]) {
        all = content
    }

    /// Returns the articles of one type.
    /// - Parameter type: The type to look for. An article's type is the first subdirectory
    /// of its Markdown file, so a file in Content/stories has the type "stories".
    /// - Returns: The matching articles, or an empty array if there are none.
    public func typed(_ type: String) -> [Article] {
        all.filter { $0.type == type }
    }

    /// Returns the articles that have the given tag.
    /// - Parameter tag: The tag to look for. It must match the article's tag exactly,
    /// including its case.
    /// - Returns: The matching articles, or an empty array if there are none.
    public func tagged(_ tag: String) -> [Article] {
        all.filter { $0.tags?.contains(tag) == true }
    }
}
