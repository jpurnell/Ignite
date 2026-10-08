//
// LinkGroup.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// A hyperlink to another resource on this site or elsewhere.
public struct LinkGroup: HTML {
    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The content to display inside this link.
    var content: any BodyElement

    /// The location to which this link should direct users.
    var url: String

    /// Whether `url`, when it is a path from the root, names a page of this site rather
    /// than an address the author wrote out. See `Link.isSitePath`.
    var isSitePath = false

    /// Creates a `Link` instance from the content you provide, linking to the
    /// URL specified.
    /// - Parameters:
    ///   - target: The URL you want to link to.
    ///   - content: The user-facing content to show inside the `Link`.
    public init(target: String, @HTMLBuilder content: @escaping () -> some HTML) {
        self.content = content()
        self.url = target
    }

    /// Creates a `LinkGroup` wrapping the provided content and pointing to a path
    /// within this site.
    ///
    /// The path is taken from the root of the site, not of the host, so the link reaches
    /// the same page wherever the site is deployed; `init(target:content:)` writes a
    /// path from the root as given, which on a site deployed in a subdirectory leads
    /// outside it. Anything that is not a path from the root is written as given.
    /// - Parameters:
    ///   - sitePath: A path from the root of this site, beginning with `/`.
    ///   - content: The user-facing content to show inside the `LinkGroup`.
    public init(sitePath: String, @HTMLBuilder content: @escaping () -> some HTML) {
        self.content = content()
        self.url = sitePath
        self.isSitePath = true
    }

    /// Creates a Link wrapping the provided content and pointing to the given page
    /// - Parameters:
    ///  - target: The new target to apply.
    ///  - content: The user-facing content to show inside the `Link`.
    public init(target: any StaticPage, @HTMLBuilder content: @escaping () -> some HTML) {
        self.content = content()
        self.url = target.path
        self.isSitePath = true
    }

    /// Creates a `Link` wrapping the provided content and pointing to the path
    /// of the `Article` instance you provide.
    /// - Parameters:
    ///   - article: An article in your site.
    ///   - content: The user-facing content to show inside the `Link`.
    public init(target article: Article, @HTMLBuilder content: @escaping () -> some HTML) {
        self.content = content()
        self.url = article.path
        self.isSitePath = true
    }

    /// Controls in which window this page should be opened.
    /// - Parameter target: The new target to apply.
    /// - Returns: A new `Link` instance with the updated target.
    public func target(_ target: LinkTarget) -> Self {
        if let name = target.name {
            var copy = self
            let attribute = Attribute(name: "target", value: name)
            copy.attributes.append(customAttributes: attribute)
            return copy
        } else {
            return self
        }
    }

    /// Sets one or more relationships for this link, which provides metadata
    /// describing what this content means or how it should be used.
    /// - Parameter relationship: The extra relationships to add.
    /// - Returns: A new `Link` instance with the updated relationships.
    public func relationship(_ relationship: LinkRelationship...) -> Self {
        var copy = self
        let attributeValue = relationship.map(\.rawValue).joined(separator: " ")
        let attribute = Attribute(name: "rel", value: attributeValue)
        copy.attributes.append(customAttributes: attribute)
        return copy
    }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        isPrivacySensitive
            ? renderPrivacyProtectedLink()
            : renderStandardLink()
    }

    /// Whether this link contains sensitive content that should be protected
    private var isPrivacySensitive: Bool {
        attributes.customAttributes.contains { $0.name == "privacy-sensitive" }
    }

    /// Renders a link with privacy protection enabled, encoding the URL and optionally the display content.
    /// - Parameter context: The current publishing context.
    /// - Returns: An HTML anchor tag with encoded attributes and content.
    private func renderPrivacyProtectedLink() -> Markup {
        let displayText = content.markupString()
        let encodingType = attributes.customAttributes.first { $0.name == "privacy-sensitive" }?.value ?? "urlOnly"

        let encodedUrl = Data(url.utf8).base64EncodedString()
        let displayContent = switch encodingType {
        case "urlAndDisplay": Data(displayText.utf8).base64EncodedString()
        default: displayText
        }

        var linkAttributes = attributes.appending(classes: "link-plain", "d-inline-block")
        linkAttributes.append(classes: "protected-link")
        linkAttributes.append(dataAttributes: .init(name: "encoded-url", value: encodedUrl))
        linkAttributes.append(customAttributes: .init(name: "href", value: "#"))

        return Markup("<a\(linkAttributes)>\(displayContent)</a>")
    }

    /// Renders a standard link with the provided URL and content.
    /// - Returns: An HTML anchor tag with the appropriate href and content.
    private func renderStandardLink() -> Markup {
        var linkAttributes = attributes.appending(classes: "link-plain", "d-inline-block")

        guard let url = URL(markupReference: url) else {
            publishingContext.addWarning("One of your links uses an invalid URL.")
            return Markup()
        }

        let path = publishingContext.linkPath(for: url, withinSite: isSitePath)
        linkAttributes.append(customAttributes: .init(name: "href", value: path))
        let contentHTML = content.markupString()
        return Markup("<a\(linkAttributes)>\(contentHTML)</a>")
    }
}
