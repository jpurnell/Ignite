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
@MainActor
public struct StructuredData: HeadElement {
    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// How the JSON-LD content is specified.
    private enum Content {
        /// A pre-built JSON string, rendered as-is.
        case raw(String)

        /// A schema type and properties, serialized at render time.
        case schema(context: String, type: String, properties: [String: Any])

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
        self.content = .schema(context: context, type: type, properties: properties)
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
        case .schema(let context, let type, let properties):
            Self.renderSchema(context: context, type: type, properties: properties)
        case .article(let publisher, let publisherURL):
            Self.renderArticle(publisher: publisher, publisherURL: publisherURL)
        case .breadcrumbs(let homeName):
            Self.renderBreadcrumbs(homeName: homeName)
        }

        guard let json, !json.isEmpty else { return Markup() }
        return Markup("<script type=\"application/ld+json\">\n\(json)\n</script>")
    }
}

// MARK: - Schema Rendering

extension StructuredData {
    /// Builds a JSON-LD string from context, type, and properties.
    private static func renderSchema(
        context: String,
        type: String,
        properties: [String: Any]
    ) -> String? {
        var json = properties
        json["@context"] = context
        json["@type"] = type
        return toJSON(json)
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

// MARK: - JSON Helpers

extension StructuredData {
    /// Serializes a dictionary to a pretty-printed JSON string.
    private static func toJSON(_ dict: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(dict),
              let data = try? JSONSerialization.data(
                  withJSONObject: dict,
                  options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
              ),
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    /// Formats a date as an ISO 8601 date-time string.
    private static func isoDateTime(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
