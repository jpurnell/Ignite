//
// DefaultLayout.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// The layout you assigned to `Site`'s `layout` property.
public struct DefaultLayout: Layout {
    /// The document produced by the layout assigned to the site.
    public var body: some Document {
        let layout = PublishingContext.shared.site.layout
        let content = layout.documentContent()
        return PlainDocument(head: content.head, body: content.body)
    }
}
