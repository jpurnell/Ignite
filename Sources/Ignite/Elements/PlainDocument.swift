//
// PlainDocument.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// An HTML document with no extra attributes applied.
public struct PlainDocument: Document, HTML {
    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    private var language: Language
    /// The metadata of the document, rendered as its `<head>` element.
    public var head: Head
    /// The visible content of the document, rendered as its `<body>` element.
    public var body: Body

    init(head: Head, body: Body) {
        self.language = PublishingContext.shared.environment.language
        self.head = head
        self.body = body
    }

    /// Creates a document from a head and a body.
    /// - Parameter content: A builder that returns the document's head and body.
    public init(@DocumentElementBuilder content: () -> (head: Head, body: Body)) {
        self.language = PublishingContext.shared.environment.language
        self.head = content().head
        self.body = content().body
    }

    /// Renders the complete page: the doctype followed by an `<html>` element that carries
    /// the site's language and the IDs of its light and dark themes.
    ///
    /// The body is rendered before the head, so that anything the body registers while it
    /// renders can still be included in the head.
    /// - Returns: The HTML for this document.
    public func markup() -> Markup {
        var attributes = attributes
        attributes.append(customAttributes: .init(name: "lang", value: language.rawValue))

        let site = PublishingContext.shared.site
        if let lightTheme = site.lightTheme {
            attributes.append(customAttributes: .init(name: "data-light-theme", value: lightTheme.cssID))
        }
        if let darkTheme = site.darkTheme {
            attributes.append(customAttributes: .init(name: "data-dark-theme", value: darkTheme.cssID))
        }

        let bodyMarkup = body.markup()
        // Deferred head rendering to accommodate for context updates during body rendering
        let headMarkup = head.markup()

        var output: Markup = "<!doctype html>"
        output += "<html\(attributes)>"
        output += headMarkup
        output += bodyMarkup
        output += "</html>"
        return output
    }
}
