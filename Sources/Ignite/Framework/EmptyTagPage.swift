//
// EmptyTagPage.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A default tag page that does nothing; used to disable tag pages entirely.
public struct EmptyTagPage: TagPage {
    /// Creates an empty tag page.
    public init() {}

    /// An empty page body, so nothing is rendered.
    public var body: some BodyElement {
        EmptyHTML()
    }
}
