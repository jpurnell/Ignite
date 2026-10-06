//
// EmptyErrorPage.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A default error page that does nothing.
public struct EmptyErrorPage: ErrorPage {

    /// Creates an empty error page.
    public init() {}

    /// An empty title.
    public var title: String {
        ""
    }

    /// An empty page body, so nothing is rendered.
    public var body: some BodyElement {
        EmptyHTML()
    }
}
