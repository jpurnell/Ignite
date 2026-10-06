//
// StructuredData.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// A head element that renders JSON-LD structured data.
///
/// Use `StructuredData` to add Schema.org (or any JSON-LD) structured data
/// to your pages. You can create schemas from a type and properties dictionary,
/// from a raw JSON string, or use the built-in convenience methods for
/// common schema types.
///
/// ```swift
/// // Generic — any schema type
/// Head {
///     StructuredData("LocalBusiness", properties: [
///         "name": "Joe's Pizza",
///         "telephone": "555-0123"
///     ])
/// }
///
/// // Convenience methods
/// Head {
///     StructuredData.organization(name: "Acme", url: "https://acme.com")
///     StructuredData.breadcrumbs()
///     StructuredData.article()
/// }
///
/// // Raw JSON-LD
/// Head {
///     StructuredData(json: customJSONString)
/// }
/// ```
public struct StructuredData: HeadElement, Sendable {
    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// How the JSON-LD content is specified.
    private enum Content: Sendable {
        /// A pre-built JSON string, rendered as-is.
        case raw(String)

        /// A schema type and properties, pre-serialized to JSON at init time.
        case schema(String)

        /// Auto-generated Article schema from the current article context.
        case article(publisher: String?, publisherURL: String?)

        /// Auto-generated BreadcrumbList from the current page context.
        case breadcrumbs(homeName: String)
    }

    private let content: Content

    // MARK: - Generic Initializers

    /// Creates structured data from a Schema.org type and properties.
    ///
    /// - Parameters:
    ///   - type: The Schema.org type (e.g., "Organization", "Event", "Product").
    ///   - context: The JSON-LD context URL. Defaults to `https://schema.org`.
    ///   - properties: A dictionary of properties for the schema. Values can be
    ///     strings, numbers, arrays, or nested dictionaries for sub-schemas.
    public init(
        _ type: String,
        context: String = "https://schema.org",
        properties: [String: Any] = [:]
    ) {
        var json = properties
        json["@context"] = context
        json["@type"] = type
        self.content = .schema(Self.toJSON(json) ?? "")
    }

    /// Creates structured data from a raw JSON-LD string.
    ///
    /// Use this when you have pre-formatted JSON-LD or need full
    /// control over the output.
    ///
    /// - Parameter json: A valid JSON-LD string.
    public init(json: String) {
        self.content = .raw(json)
    }

    private init(content: Content) {
        self.content = content
    }

    // MARK: - Rendering

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        let json: String? = switch content {
        case .raw(let string):
            string
        case .schema(let serialized):
            serialized.isEmpty ? nil : serialized
        case .article(let publisher, let publisherURL):
            Self.renderArticle(publisher: publisher, publisherURL: publisherURL)
        case .breadcrumbs(let homeName):
            Self.renderBreadcrumbs(homeName: homeName)
        }

        guard let json, !json.isEmpty else { return Markup() }
        return Markup("<script type=\"application/ld+json\">\n\(json)\n</script>")
    }
}

// MARK: - Convenience: Article

extension StructuredData {
    /// Generates `Article` JSON-LD from the current page's article metadata.
    ///
    /// When the current page is not an article, this produces no output.
    /// The schema is populated automatically from the article's YAML
    /// front matter: title, dates, author, description, and image.
    ///
    /// - Parameters:
    ///   - publisher: Optional publisher organization name.
    ///   - publisherURL: Optional publisher organization URL.
    /// - Returns: A `StructuredData` element. Emits nothing on non-article pages.
    public static func article(
        publisher: String? = nil,
        publisherURL: String? = nil
    ) -> StructuredData {
        StructuredData(content: .article(publisher: publisher, publisherURL: publisherURL))
    }

    private static func renderArticle(publisher: String?, publisherURL: String?) -> String? {
        let environment = PublishingContext.shared.environment
        let article = environment.article

        guard !article.title.isEmpty else { return nil }

        var json: [String: Any] = [
            "@context": "https://schema.org",
            "@type": "Article",
            "headline": article.title,
            "url": environment.page.url.absoluteString,
            "datePublished": isoDateTime(article.date)
        ]

        if article.lastModified != article.date {
            json["dateModified"] = isoDateTime(article.lastModified)
        }

        if !article.description.isEmpty {
            json["description"] = article.description
        }

        if let image = article.image {
            let siteBase = environment.site.url.absoluteString
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            json["image"] = image.hasPrefix("/") ? siteBase + image : image
        }

        let authorName = article.author
            ?? (environment.author.isEmpty ? nil : environment.author)
        if let authorName {
            json["author"] = ["@type": "Person", "name": authorName]
        }

        if let publisher {
            var pub: [String: Any] = ["@type": "Organization", "name": publisher]
            if let publisherURL { pub["url"] = publisherURL }
            json["publisher"] = pub
        }

        return toJSON(json)
    }
}

// MARK: - Convenience: Organization

extension StructuredData {
    /// Generates `Organization` JSON-LD.
    ///
    /// - Parameters:
    ///   - name: The organization name.
    ///   - url: The organization's website URL.
    ///   - description: A brief description of the organization.
    ///   - foundingDate: The founding date in ISO 8601 format (e.g., "2000-06-06").
    ///   - sameAs: URLs for the organization's social media profiles or external pages.
    ///   - parentOrganization: An optional parent organization as (name, url).
    ///   - parentOrganizationType: The Schema.org type for the parent. Defaults to "Organization".
    public static func organization(
        name: String,
        url: String,
        description: String? = nil,
        foundingDate: String? = nil,
        sameAs: [String] = [],
        parentOrganization: (name: String, url: String)? = nil,
        parentOrganizationType: String = "Organization"
    ) -> StructuredData {
        var properties: [String: Any] = [
            "name": name,
            "url": url
        ]

        if let description { properties["description"] = description }
        if let foundingDate { properties["foundingDate"] = foundingDate }
        if !sameAs.isEmpty { properties["sameAs"] = sameAs }

        if let parent = parentOrganization {
            properties["parentOrganization"] = [
                "@type": parentOrganizationType,
                "name": parent.name,
                "url": parent.url
            ]
        }

        return StructuredData("Organization", properties: properties)
    }
}

// MARK: - Convenience: WebSite

extension StructuredData {
    /// Generates `WebSite` JSON-LD.
    ///
    /// - Parameters:
    ///   - name: The website name.
    ///   - url: The website URL.
    ///   - description: A brief description of the website.
    public static func webSite(
        name: String,
        url: String,
        description: String? = nil
    ) -> StructuredData {
        var properties: [String: Any] = [
            "name": name,
            "url": url
        ]

        if let description { properties["description"] = description }

        return StructuredData("WebSite", properties: properties)
    }
}

// MARK: - Convenience: Event

extension StructuredData {
    /// Generates `Event` JSON-LD.
    ///
    /// - Parameters:
    ///   - name: The event name.
    ///   - startDate: Start date in ISO 8601 format (e.g., "2026-05-24").
    ///   - endDate: End date in ISO 8601 format.
    ///   - locationName: The venue or place name.
    ///   - locality: The city.
    ///   - region: The state or province abbreviation.
    ///   - postalCode: The postal or ZIP code.
    ///   - country: The country code. Defaults to "US".
    ///   - organizer: An optional organizer as (name, url).
    ///   - status: The event status. Defaults to "EventScheduled".
    ///   - attendanceMode: The attendance mode. Defaults to "OfflineEventAttendanceMode".
    public static func event(
        name: String,
        startDate: String,
        endDate: String,
        locationName: String,
        locality: String,
        region: String,
        postalCode: String,
        country: String = "US",
        organizer: (name: String, url: String)? = nil,
        status: String = "EventScheduled",
        attendanceMode: String = "OfflineEventAttendanceMode"
    ) -> StructuredData {
        var properties: [String: Any] = [
            "name": name,
            "startDate": startDate,
            "endDate": endDate,
            "eventAttendanceMode": "https://schema.org/\(attendanceMode)",
            "eventStatus": "https://schema.org/\(status)",
            "location": [
                "@type": "Place",
                "name": locationName,
                "address": [
                    "@type": "PostalAddress",
                    "addressLocality": locality,
                    "addressRegion": region,
                    "postalCode": postalCode,
                    "addressCountry": country
                ] as [String: Any]
            ] as [String: Any]
        ]

        if let organizer {
            properties["organizer"] = [
                "@type": "Organization",
                "name": organizer.name,
                "url": organizer.url
            ]
        }

        return StructuredData("Event", properties: properties)
    }
}

// MARK: - Convenience: BreadcrumbList

extension StructuredData {
    /// Generates `BreadcrumbList` JSON-LD from the current page context.
    ///
    /// Automatically creates a two-level breadcrumb: Home → Current Page.
    /// Produces no output on the homepage.
    ///
    /// - Parameter homeName: The label for the home breadcrumb. Defaults to "Home".
    /// - Returns: A `StructuredData` element. Emits nothing on the homepage.
    public static func breadcrumbs(
        homeName: String = "Home"
    ) -> StructuredData {
        StructuredData(content: .breadcrumbs(homeName: homeName))
    }

    private static func renderBreadcrumbs(homeName: String) -> String? {
        let environment = PublishingContext.shared.environment
        let page = environment.page
        let siteURL = environment.site.url

        let pagePath = page.url.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard !pagePath.isEmpty else { return nil }

        let json: [String: Any] = [
            "@context": "https://schema.org",
            "@type": "BreadcrumbList",
            "itemListElement": [
                [
                    "@type": "ListItem",
                    "position": 1,
                    "name": homeName,
                    "item": siteURL.absoluteString
                ] as [String: Any],
                [
                    "@type": "ListItem",
                    "position": 2,
                    "name": page.title,
                    "item": page.url.absoluteString
                ] as [String: Any]
            ]
        ]

        return toJSON(json)
    }
}

// MARK: - @graph Support

extension StructuredData {
    /// Creates a single JSON-LD `@graph` block from an array of node dictionaries.
    ///
    /// Each node should be a Schema.org typed dictionary (with `@type` and optionally `@id`).
    /// The result is one `<script type="application/ld+json">` containing
    /// `{"@context": "https://schema.org", "@graph": [...]}`.
    ///
    /// - Parameter nodes: An array of node dictionaries to include in the graph.
    /// - Returns: A `StructuredData` element. Emits nothing if nodes is empty.
    public static func graph(nodes: [[String: Any]]) -> StructuredData {
        guard !nodes.isEmpty else { return StructuredData(json: "") }
        let wrapper: [String: Any] = [
            "@context": "https://schema.org",
            "@graph": nodes
        ]
        return StructuredData(json: toJSON(wrapper) ?? "")
    }
}

// MARK: - Node Builders

extension StructuredData {
    /// Builds a `Person` node dictionary for use in a `@graph`.
    ///
    /// - Parameters:
    ///   - name: The person's name.
    ///   - url: The person's URL.
    ///   - sameAs: URLs for social profiles or external pages.
    ///   - id: An optional `@id` for cross-referencing within a graph.
    /// - Returns: A `[String: Any]` dictionary representing the Person node.
    public static func personNode(
        name: String,
        url: String,
        sameAs: [String] = [],
        id: String? = nil
    ) -> [String: Any] {
        var node: [String: Any] = [
            "@type": "Person",
            "name": name,
            "url": url
        ]
        if let id { node["@id"] = id }
        if !sameAs.isEmpty { node["sameAs"] = sameAs }
        return node
    }

    /// Builds a `WebSite` node dictionary for use in a `@graph`.
    ///
    /// - Parameters:
    ///   - name: The website name.
    ///   - url: The website URL.
    ///   - description: A brief description of the website.
    ///   - inLanguage: The BCP-47 language code (e.g., "en-US").
    ///   - publisherId: An `@id` reference to the publisher node.
    ///   - id: An optional `@id` for cross-referencing within a graph.
    /// - Returns: A `[String: Any]` dictionary representing the WebSite node.
    public static func webSiteNode(
        name: String,
        url: String,
        description: String? = nil,
        inLanguage: String? = nil,
        publisherId: String? = nil,
        id: String? = nil
    ) -> [String: Any] {
        var node: [String: Any] = [
            "@type": "WebSite",
            "name": name,
            "url": url
        ]
        if let id { node["@id"] = id }
        if let description { node["description"] = description }
        if let inLanguage { node["inLanguage"] = inLanguage }
        if let publisherId { node["publisher"] = ["@id": publisherId] }
        return node
    }

    /// Builds a `WebPage` node dictionary for use in a `@graph`.
    ///
    /// - Parameters:
    ///   - url: The page URL.
    ///   - title: The page title.
    ///   - description: A brief description of the page.
    ///   - isPartOfId: An `@id` reference to the parent WebSite node.
    ///   - breadcrumbId: An `@id` reference to the BreadcrumbList node.
    ///   - id: An optional `@id` for cross-referencing within a graph.
    /// - Returns: A `[String: Any]` dictionary representing the WebPage node.
    public static func webPageNode(
        url: String,
        title: String,
        description: String? = nil,
        isPartOfId: String? = nil,
        breadcrumbId: String? = nil,
        id: String? = nil
    ) -> [String: Any] {
        var node: [String: Any] = [
            "@type": "WebPage",
            "name": title,
            "url": url
        ]
        if let id { node["@id"] = id }
        if let description { node["description"] = description }
        if let isPartOfId { node["isPartOf"] = ["@id": isPartOfId] }
        if let breadcrumbId { node["breadcrumb"] = ["@id": breadcrumbId] }
        return node
    }

    /// Builds a `ProfilePage` node dictionary for use in a `@graph`.
    ///
    /// - Parameters:
    ///   - url: The page URL.
    ///   - title: The page title.
    ///   - description: A brief description of the page.
    ///   - mainEntityId: An `@id` reference to the main entity (typically a Person).
    ///   - isPartOfId: An `@id` reference to the parent WebSite node.
    ///   - id: An optional `@id` for cross-referencing within a graph.
    /// - Returns: A `[String: Any]` dictionary representing the ProfilePage node.
    public static func profilePageNode(
        url: String,
        title: String,
        description: String? = nil,
        mainEntityId: String? = nil,
        isPartOfId: String? = nil,
        id: String? = nil
    ) -> [String: Any] {
        var node: [String: Any] = [
            "@type": "ProfilePage",
            "name": title,
            "url": url
        ]
        if let id { node["@id"] = id }
        if let description { node["description"] = description }
        if let mainEntityId { node["mainEntity"] = ["@id": mainEntityId] }
        if let isPartOfId { node["isPartOf"] = ["@id": isPartOfId] }
        return node
    }

    /// Builds a `CollectionPage` node dictionary for use in a `@graph`.
    ///
    /// - Parameters:
    ///   - url: The page URL.
    ///   - title: The page title.
    ///   - description: A brief description of the page.
    ///   - isPartOfId: An `@id` reference to the parent WebSite node.
    ///   - mainEntityId: An `@id` reference to the main entity.
    ///   - id: An optional `@id` for cross-referencing within a graph.
    /// - Returns: A `[String: Any]` dictionary representing the CollectionPage node.
    public static func collectionPageNode(
        url: String,
        title: String,
        description: String? = nil,
        isPartOfId: String? = nil,
        mainEntityId: String? = nil,
        id: String? = nil
    ) -> [String: Any] {
        var node: [String: Any] = [
            "@type": "CollectionPage",
            "name": title,
            "url": url
        ]
        if let id { node["@id"] = id }
        if let description { node["description"] = description }
        if let isPartOfId { node["isPartOf"] = ["@id": isPartOfId] }
        if let mainEntityId { node["mainEntity"] = ["@id": mainEntityId] }
        return node
    }

    /// Builds an `Article` node dictionary for use in a `@graph`.
    ///
    /// Unlike the `article()` convenience method, this does not read from the
    /// publishing environment — all values are passed explicitly, making it
    /// composable into a `@graph`.
    ///
    /// - Parameters:
    ///   - headline: The article headline.
    ///   - url: The article URL.
    ///   - datePublished: The ISO 8601 publication date string.
    ///   - dateModified: An optional ISO 8601 modification date string.
    ///   - description: A brief article description.
    ///   - image: An image URL for the article.
    ///   - authorId: An `@id` reference to the author node.
    ///   - publisherId: An `@id` reference to the publisher node.
    ///   - isPartOfId: An `@id` reference to the parent WebSite node.
    ///   - id: An optional `@id` for cross-referencing within a graph.
    /// - Returns: A `[String: Any]` dictionary representing the Article node.
    public static func articleNode(
        headline: String,
        url: String,
        datePublished: String,
        dateModified: String? = nil,
        description: String? = nil,
        image: String? = nil,
        authorId: String? = nil,
        publisherId: String? = nil,
        isPartOfId: String? = nil,
        id: String? = nil
    ) -> [String: Any] {
        var node: [String: Any] = [
            "@type": "Article",
            "headline": headline,
            "url": url,
            "datePublished": datePublished
        ]
        if let id { node["@id"] = id }
        if let dateModified { node["dateModified"] = dateModified }
        if let description { node["description"] = description }
        if let image { node["image"] = image }
        if let authorId { node["author"] = ["@id": authorId] }
        if let publisherId { node["publisher"] = ["@id": publisherId] }
        if let isPartOfId { node["isPartOf"] = ["@id": isPartOfId] }
        return node
    }

    /// Builds a `BreadcrumbList` node dictionary for use in a `@graph`.
    ///
    /// Creates a two-level breadcrumb: Home → Current Page.
    ///
    /// - Parameters:
    ///   - siteURL: The site's root URL.
    ///   - pageURL: The current page URL.
    ///   - pageTitle: The current page title.
    ///   - homeName: The label for the home breadcrumb. Defaults to "Home".
    ///   - id: An optional `@id` for cross-referencing within a graph.
    /// - Returns: A `[String: Any]` dictionary representing the BreadcrumbList node.
    public static func breadcrumbListNode(
        siteURL: String,
        pageURL: String,
        pageTitle: String,
        homeName: String = "Home",
        id: String? = nil
    ) -> [String: Any] {
        var node: [String: Any] = [
            "@type": "BreadcrumbList",
            "itemListElement": [
                [
                    "@type": "ListItem",
                    "position": 1,
                    "name": homeName,
                    "item": siteURL
                ] as [String: Any],
                [
                    "@type": "ListItem",
                    "position": 2,
                    "name": pageTitle,
                    "item": pageURL
                ] as [String: Any]
            ]
        ]
        if let id { node["@id"] = id }
        return node
    }
}

// MARK: - JSON Helpers

extension StructuredData {
    /// Serializes a dictionary to a pretty-printed JSON string.
    private static func toJSON(_ dict: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(dict) else { return nil }

        do {
            let data = try JSONSerialization.data(
                withJSONObject: dict,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            return String(data: data, encoding: .utf8)
        } catch {
            logger.error("Failed to serialize structured data: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Formats a date as an ISO 8601 date-time string.
    private static func isoDateTime(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
