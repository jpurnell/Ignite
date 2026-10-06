//
// EmptyLayout.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A layout that applies almost no styling.
public struct EmptyLayout: Layout {
    /// A document that holds only the page's content inside a `<body>` element.
    public var body: some Document {
        Body()
    }

    /// Creates an empty layout.
    public init() {}
}
