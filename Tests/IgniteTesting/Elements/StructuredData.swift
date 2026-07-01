//
// StructuredData.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `StructuredData` element.
@Suite("StructuredData Tests")
@MainActor class StructuredDataTests: IgniteTestSuite {

    // MARK: - Helpers

    /// Creates an Article with the given properties for testing.
    private func makeArticle(
        title: String = "",
        description: String = "",
        path: String = "",
        metadata: [String: any Sendable] = [:],
        text: String = ""
    ) -> Article {
        var article = Article()
        article.title = title
        article.description = description
        article.path = path
        article.metadata = metadata
        article.text = text
        return article
    }

    /// Runs a closure with a custom article and page injected into the environment.
    private func withArticleContext(
        article: Article,
        pageURL: URL = URL(string: "https://www.example.com/test-article")!,
        pageTitle: String = "Test Article",
        operation: () -> String
    ) -> String {
        var env = EnvironmentValues()
        env.article = article
        env.page = PageMetadata(
            title: pageTitle,
            description: article.description,
            url: pageURL
        )
        return PublishingContext.shared.withEnvironment(env) {
            operation()
        }
    }

    /// Runs a closure with a custom page injected into the environment.
    private func withPageContext(
        pageURL: URL,
        pageTitle: String = "",
        operation: () -> String
    ) -> String {
        var env = EnvironmentValues()
        env.page = PageMetadata(
            title: pageTitle,
            description: "",
            url: pageURL
        )
        return PublishingContext.shared.withEnvironment(env) {
            operation()
        }
    }

    // MARK: - Generic Initializer Tests

    @Test("Generic schema renders JSON-LD script tag", .publishingContext())
    func genericSchema() async throws {
        let element = StructuredData("LocalBusiness", properties: [
            "name": "Joe's Pizza",
            "telephone": "555-0123"
        ])
        let output = element.markupString()

        #expect(output.contains("<script type=\"application/ld+json\">"))
        #expect(output.contains("</script>"))
        #expect(output.contains("\"@context\" : \"https://schema.org\""))
        #expect(output.contains("\"@type\" : \"LocalBusiness\""))
        #expect(output.contains("\"name\" : \"Joe's Pizza\""))
        #expect(output.contains("\"telephone\" : \"555-0123\""))
    }

    @Test("Raw JSON renders as-is", .publishingContext())
    func rawJSON() async throws {
        let json = """
        {"@context":"https://schema.org","@type":"Thing","name":"Test"}
        """
        let element = StructuredData(json: json)
        let output = element.markupString()

        #expect(output.contains("<script type=\"application/ld+json\">"))
        #expect(output.contains(json))
        #expect(output.contains("</script>"))
    }

    @Test("Custom context overrides default", .publishingContext())
    func customContext() async throws {
        let element = StructuredData(
            "Dataset",
            context: "https://example.org/custom",
            properties: ["name": "Test"]
        )
        let output = element.markupString()

        #expect(output.contains("\"@context\" : \"https://example.org/custom\""))
        #expect(output.contains("\"@type\" : \"Dataset\""))
    }

    @Test("Empty properties still renders valid JSON-LD", .publishingContext())
    func emptyProperties() async throws {
        let element = StructuredData("Thing")
        let output = element.markupString()

        #expect(output.contains("\"@context\" : \"https://schema.org\""))
        #expect(output.contains("\"@type\" : \"Thing\""))
    }

    @Test("Nested dictionary properties render correctly", .publishingContext())
    func nestedProperties() async throws {
        let element = StructuredData("Product", properties: [
            "name": "Widget",
            "offers": [
                "@type": "Offer",
                "price": "9.99",
                "priceCurrency": "USD"
            ] as [String: Any]
        ])
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Product\""))
        #expect(output.contains("\"name\" : \"Widget\""))
        #expect(output.contains("\"price\" : \"9.99\""))
        #expect(output.contains("\"priceCurrency\" : \"USD\""))
    }

    @Test("Array properties render correctly", .publishingContext())
    func arrayProperties() async throws {
        let element = StructuredData("Organization", properties: [
            "name": "Test Org",
            "sameAs": ["https://twitter.com/test", "https://facebook.com/test"]
        ])
        let output = element.markupString()

        #expect(output.contains("\"https://twitter.com/test\""))
        #expect(output.contains("\"https://facebook.com/test\""))
    }

    // MARK: - Organization Tests

    @Test("Organization with all fields", .publishingContext())
    func organizationFull() async throws {
        let element = StructuredData.organization(
            name: "Acme Corp",
            url: "https://acme.com",
            description: "A test company",
            foundingDate: "2000-01-01",
            sameAs: ["https://twitter.com/acme", "https://linkedin.com/company/acme"],
            parentOrganization: (name: "Parent Inc", url: "https://parent.com")
        )
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Organization\""))
        #expect(output.contains("\"name\" : \"Acme Corp\""))
        #expect(output.contains("\"url\" : \"https://acme.com\""))
        #expect(output.contains("\"description\" : \"A test company\""))
        #expect(output.contains("\"foundingDate\" : \"2000-01-01\""))
        #expect(output.contains("\"https://twitter.com/acme\""))
        #expect(output.contains("\"https://linkedin.com/company/acme\""))
        #expect(output.contains("\"name\" : \"Parent Inc\""))
        #expect(output.contains("\"url\" : \"https://parent.com\""))
    }

    @Test("Organization without optional fields", .publishingContext())
    func organizationMinimal() async throws {
        let element = StructuredData.organization(
            name: "Simple Org",
            url: "https://simple.org"
        )
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Organization\""))
        #expect(output.contains("\"name\" : \"Simple Org\""))
        #expect(!output.contains("\"description\""))
        #expect(!output.contains("\"foundingDate\""))
        #expect(!output.contains("\"sameAs\""))
        #expect(!output.contains("\"parentOrganization\""))
    }

    @Test("Organization with custom parent type", .publishingContext())
    func organizationCustomParentType() async throws {
        let element = StructuredData.organization(
            name: "CS Department",
            url: "https://cs.example.edu",
            parentOrganization: (name: "Example University", url: "https://example.edu"),
            parentOrganizationType: "EducationalOrganization"
        )
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"EducationalOrganization\""))
        #expect(output.contains("\"name\" : \"Example University\""))
    }

    // MARK: - WebSite Tests

    @Test("WebSite with all fields", .publishingContext())
    func webSiteFull() async throws {
        let element = StructuredData.webSite(
            name: "My Site",
            url: "https://example.com",
            description: "A test site"
        )
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"WebSite\""))
        #expect(output.contains("\"name\" : \"My Site\""))
        #expect(output.contains("\"url\" : \"https://example.com\""))
        #expect(output.contains("\"description\" : \"A test site\""))
    }

    @Test("WebSite without description", .publishingContext())
    func webSiteMinimal() async throws {
        let element = StructuredData.webSite(
            name: "Minimal Site",
            url: "https://minimal.com"
        )
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"WebSite\""))
        #expect(output.contains("\"name\" : \"Minimal Site\""))
        #expect(!output.contains("\"description\""))
    }

    // MARK: - Event Tests

    @Test("Event with all fields", .publishingContext())
    func eventFull() async throws {
        let element = StructuredData.event(
            name: "Annual Conference",
            startDate: "2026-06-01",
            endDate: "2026-06-03",
            locationName: "Convention Center",
            locality: "Springfield",
            region: "IL",
            postalCode: "62701",
            organizer: (name: "Org Co", url: "https://org.com")
        )
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Event\""))
        #expect(output.contains("\"name\" : \"Annual Conference\""))
        #expect(output.contains("\"startDate\" : \"2026-06-01\""))
        #expect(output.contains("\"endDate\" : \"2026-06-03\""))
        #expect(output.contains("\"name\" : \"Convention Center\""))
        #expect(output.contains("\"addressLocality\" : \"Springfield\""))
        #expect(output.contains("\"addressRegion\" : \"IL\""))
        #expect(output.contains("\"postalCode\" : \"62701\""))
        #expect(output.contains("\"addressCountry\" : \"US\""))
        #expect(output.contains("\"https://schema.org/OfflineEventAttendanceMode\""))
        #expect(output.contains("\"https://schema.org/EventScheduled\""))
        #expect(output.contains("\"name\" : \"Org Co\""))
        #expect(output.contains("\"url\" : \"https://org.com\""))
    }

    @Test("Event without organizer", .publishingContext())
    func eventWithoutOrganizer() async throws {
        let element = StructuredData.event(
            name: "Simple Event",
            startDate: "2026-01-01",
            endDate: "2026-01-02",
            locationName: "Venue",
            locality: "City",
            region: "ST",
            postalCode: "00000"
        )
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Event\""))
        #expect(!output.contains("\"organizer\""))
    }

    @Test("Event with custom status and attendance mode", .publishingContext())
    func eventCustomStatus() async throws {
        let element = StructuredData.event(
            name: "Virtual Meetup",
            startDate: "2026-03-01",
            endDate: "2026-03-01",
            locationName: "Online",
            locality: "Internet",
            region: "NA",
            postalCode: "00000",
            status: "EventPostponed",
            attendanceMode: "OnlineEventAttendanceMode"
        )
        let output = element.markupString()

        #expect(output.contains("\"https://schema.org/EventPostponed\""))
        #expect(output.contains("\"https://schema.org/OnlineEventAttendanceMode\""))
    }

    @Test("Event with non-US country", .publishingContext())
    func eventNonUSCountry() async throws {
        let element = StructuredData.event(
            name: "London Summit",
            startDate: "2026-09-15",
            endDate: "2026-09-17",
            locationName: "ExCeL London",
            locality: "London",
            region: "England",
            postalCode: "E16 1XL",
            country: "GB"
        )
        let output = element.markupString()

        #expect(output.contains("\"addressCountry\" : \"GB\""))
        #expect(output.contains("\"addressLocality\" : \"London\""))
    }

    // MARK: - BreadcrumbList Tests

    @Test("Breadcrumbs renders BreadcrumbList schema", .publishingContext())
    func breadcrumbs() async throws {
        let output = withPageContext(
            pageURL: URL(string: "https://www.example.com/about/")!,
            pageTitle: "About"
        ) {
            StructuredData.breadcrumbs().markupString()
        }

        #expect(output.contains("\"@type\" : \"BreadcrumbList\""))
        #expect(output.contains("\"@type\" : \"ListItem\""))
        #expect(output.contains("\"position\" : 1"))
        #expect(output.contains("\"position\" : 2"))
        #expect(output.contains("\"name\" : \"Home\""))
    }

    @Test("Breadcrumbs uses custom home name", .publishingContext())
    func breadcrumbsCustomName() async throws {
        let output = withPageContext(
            pageURL: URL(string: "https://www.example.com/about/")!,
            pageTitle: "About"
        ) {
            StructuredData.breadcrumbs(homeName: "Start").markupString()
        }

        #expect(output.contains("\"name\" : \"Start\""))
    }

    @Test("Breadcrumbs emits nothing on homepage", .publishingContext())
    func breadcrumbsHomepage() async throws {
        let output = withPageContext(
            pageURL: URL(string: "https://www.example.com/")!
        ) {
            StructuredData.breadcrumbs().markupString()
        }

        #expect(output.isEmpty)
    }

    @Test("Breadcrumbs includes page title and URL", .publishingContext())
    func breadcrumbsPageInfo() async throws {
        let output = withPageContext(
            pageURL: URL(string: "https://www.example.com/about/")!,
            pageTitle: "About Us"
        ) {
            StructuredData.breadcrumbs().markupString()
        }

        #expect(output.contains("\"name\" : \"About Us\""))
        #expect(output.contains("\"item\" : \"https://www.example.com/about/\""))
    }

    // MARK: - Article Tests

    @Test("Article emits nothing on non-article pages", .publishingContext())
    func articleNonArticlePage() async throws {
        let element = StructuredData.article(
            publisher: "Test Publisher",
            publisherURL: "https://publisher.com"
        )
        let output = element.markupString()

        #expect(output.isEmpty)
    }

    @Test("Article renders headline and date", .publishingContext())
    func articleBasic() async throws {
        let testDate = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14
        let article = makeArticle(
            title: "Test Article Title",
            metadata: ["date": testDate]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"@type\" : \"Article\""))
        #expect(output.contains("\"headline\" : \"Test Article Title\""))
        #expect(output.contains("\"datePublished\""))
        #expect(output.contains("\"url\" : \"https://www.example.com/test-article\""))
    }

    @Test("Article includes description when present", .publishingContext())
    func articleWithDescription() async throws {
        let article = makeArticle(
            title: "Described Article",
            description: "A thorough summary of this article."
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"description\" : \"A thorough summary of this article.\""))
    }

    @Test("Article omits description when empty", .publishingContext())
    func articleWithoutDescription() async throws {
        let article = makeArticle(title: "No Description")

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(!output.contains("\"description\""))
    }

    @Test("Article includes author from metadata", .publishingContext())
    func articleWithAuthor() async throws {
        let article = makeArticle(
            title: "Authored Article",
            metadata: ["author": "Jane Doe"]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"@type\" : \"Person\""))
        #expect(output.contains("\"name\" : \"Jane Doe\""))
    }

    @Test("Article includes image with relative path", .publishingContext())
    func articleWithRelativeImage() async throws {
        let article = makeArticle(
            title: "Image Article",
            metadata: ["image": "/images/hero.jpg"]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"image\""))
        #expect(output.contains("/images/hero.jpg"))
    }

    @Test("Article includes image with absolute URL", .publishingContext())
    func articleWithAbsoluteImage() async throws {
        let article = makeArticle(
            title: "External Image Article",
            metadata: ["image": "https://cdn.example.com/photo.jpg"]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"image\" : \"https://cdn.example.com/photo.jpg\""))
    }

    @Test("Article includes publisher", .publishingContext())
    func articleWithPublisher() async throws {
        let article = makeArticle(title: "Published Article")

        let output = withArticleContext(article: article) {
            StructuredData.article(
                publisher: "News Corp",
                publisherURL: "https://news.com"
            ).markupString()
        }

        #expect(output.contains("\"@type\" : \"Organization\""))
        #expect(output.contains("\"name\" : \"News Corp\""))
        #expect(output.contains("\"url\" : \"https://news.com\""))
    }

    @Test("Article includes publisher name without URL", .publishingContext())
    func articleWithPublisherNoURL() async throws {
        let article = makeArticle(title: "Published Article")

        let output = withArticleContext(article: article) {
            StructuredData.article(publisher: "Simple Publisher").markupString()
        }

        #expect(output.contains("\"name\" : \"Simple Publisher\""))
        let publisherRange = output.range(of: "\"publisher\"")
        #expect(publisherRange != nil)
    }

    @Test("Article omits publisher when not provided", .publishingContext())
    func articleWithoutPublisher() async throws {
        let article = makeArticle(title: "Unpublished Article")

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(!output.contains("\"publisher\""))
    }

    @Test("Article includes dateModified when different from date", .publishingContext())
    func articleWithModifiedDate() async throws {
        let publishDate = Date(timeIntervalSince1970: 1_700_000_000)
        let modifiedDate = Date(timeIntervalSince1970: 1_710_000_000)
        let article = makeArticle(
            title: "Updated Article",
            metadata: [
                "date": publishDate,
                "lastModified": modifiedDate
            ]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"datePublished\""))
        #expect(output.contains("\"dateModified\""))
    }

    @Test("Article omits dateModified when same as date", .publishingContext())
    func articleWithoutModifiedDate() async throws {
        let publishDate = Date(timeIntervalSince1970: 1_700_000_000)
        let article = makeArticle(
            title: "Unmodified Article",
            metadata: [
                "date": publishDate,
                "lastModified": publishDate
            ]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"datePublished\""))
        #expect(!output.contains("\"dateModified\""))
    }

    @Test("Article with all fields populated", .publishingContext())
    func articleFullyPopulated() async throws {
        let publishDate = Date(timeIntervalSince1970: 1_700_000_000)
        let modifiedDate = Date(timeIntervalSince1970: 1_710_000_000)
        let article = makeArticle(
            title: "Complete Article",
            description: "A fully populated test article.",
            metadata: [
                "date": publishDate,
                "lastModified": modifiedDate,
                "author": "John Smith",
                "image": "/images/article-hero.png"
            ]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article(
                publisher: "Test Publisher",
                publisherURL: "https://publisher.com"
            ).markupString()
        }

        #expect(output.contains("\"@type\" : \"Article\""))
        #expect(output.contains("\"headline\" : \"Complete Article\""))
        #expect(output.contains("\"description\" : \"A fully populated test article.\""))
        #expect(output.contains("\"datePublished\""))
        #expect(output.contains("\"dateModified\""))
        #expect(output.contains("\"name\" : \"John Smith\""))
        #expect(output.contains("/images/article-hero.png"))
        #expect(output.contains("\"name\" : \"Test Publisher\""))
        #expect(output.contains("\"url\" : \"https://publisher.com\""))
    }

    // MARK: - Edge Case Tests

    @Test("Properties with special characters are JSON-escaped", .publishingContext())
    func specialCharacters() async throws {
        let element = StructuredData("Thing", properties: [
            "name": "Joe's \"Best\" Pizza & Subs",
            "description": "Line one\nLine two"
        ])
        let output = element.markupString()

        #expect(output.contains("<script type=\"application/ld+json\">"))
        #expect(output.contains("</script>"))
        #expect(output.contains("Joe's"))
        #expect(output.contains("Pizza & Subs"))
    }

    @Test("Properties with unicode characters", .publishingContext())
    func unicodeProperties() async throws {
        let element = StructuredData("Organization", properties: [
            "name": "Caf\u{00E9} M\u{00FC}nchen \u{1F37A}",
            "description": "\u{4E16}\u{754C}\u{4F60}\u{597D}"
        ])
        let output = element.markupString()

        #expect(output.contains("Caf\u{00E9}"))
        #expect(output.contains("M\u{00FC}nchen"))
        #expect(output.contains("\u{4E16}\u{754C}\u{4F60}\u{597D}"))
    }

    @Test("Empty raw JSON renders empty output", .publishingContext())
    func emptyRawJSON() async throws {
        let element = StructuredData(json: "")
        let output = element.markupString()

        #expect(output.isEmpty)
    }

    @Test("Organization with empty sameAs array omits field", .publishingContext())
    func organizationEmptySameAs() async throws {
        let element = StructuredData.organization(
            name: "Test Org",
            url: "https://test.org",
            sameAs: []
        )
        let output = element.markupString()

        #expect(!output.contains("\"sameAs\""))
    }

    @Test("Deeply nested schema properties render correctly", .publishingContext())
    func deeplyNestedProperties() async throws {
        let element = StructuredData("Event", properties: [
            "name": "Nested Event",
            "location": [
                "@type": "Place",
                "name": "Venue",
                "address": [
                    "@type": "PostalAddress",
                    "streetAddress": "123 Main St",
                    "addressLocality": "Springfield",
                    "addressRegion": "IL",
                    "geo": [
                        "@type": "GeoCoordinates",
                        "latitude": "39.7817",
                        "longitude": "-89.6501"
                    ] as [String: Any]
                ] as [String: Any]
            ] as [String: Any]
        ])
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"GeoCoordinates\""))
        #expect(output.contains("\"latitude\" : \"39.7817\""))
        #expect(output.contains("\"streetAddress\" : \"123 Main St\""))
    }

    @Test("Article title with HTML entities", .publishingContext())
    func articleTitleWithEntities() async throws {
        let article = makeArticle(title: "Rock & Roll: A \"History\"")

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("Rock & Roll"))
        #expect(output.contains("\"@type\" : \"Article\""))
    }

    @Test("Breadcrumbs with deeply nested page path", .publishingContext())
    func breadcrumbsDeepPath() async throws {
        let output = withPageContext(
            pageURL: URL(string: "https://www.example.com/blog/2026/03/my-post/")!,
            pageTitle: "My Post"
        ) {
            StructuredData.breadcrumbs().markupString()
        }

        #expect(output.contains("\"@type\" : \"BreadcrumbList\""))
        #expect(output.contains("\"name\" : \"My Post\""))
        #expect(output.contains("blog/2026/03/my-post/"))
    }

    // MARK: - Invalid Input Tests

    @Test("Invalid JSON string produces empty output", .publishingContext())
    func invalidRawJSON() async throws {
        let element = StructuredData(json: "{invalid json{{{")
        let output = element.markupString()

        #expect(output.contains("<script type=\"application/ld+json\">"))
        #expect(output.contains("{invalid json{{{"))
    }

    @Test("Schema with empty type string still renders", .publishingContext())
    func emptyTypeString() async throws {
        let element = StructuredData("", properties: ["name": "Test"])
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"\""))
        #expect(output.contains("\"name\" : \"Test\""))
    }

    // MARK: - Property-Based Tests

    @Test("All non-empty outputs are wrapped in script tags", .publishingContext())
    func outputStructureInvariant() async throws {
        let elements: [StructuredData] = [
            StructuredData("Thing"),
            StructuredData("Product", properties: ["name": "Widget"]),
            StructuredData(json: "{\"@type\":\"Test\"}"),
            .organization(name: "Org", url: "https://org.com"),
            .webSite(name: "Site", url: "https://site.com"),
            .event(
                name: "E", startDate: "2026-01-01", endDate: "2026-01-02",
                locationName: "V", locality: "C", region: "S", postalCode: "0"
            )
        ]

        for element in elements {
            let output = element.markupString()
            if !output.isEmpty {
                #expect(output.hasPrefix("<script type=\"application/ld+json\">"))
                #expect(output.hasSuffix("</script>"))
            }
        }
    }

    @Test("All schema outputs contain @context and @type", .publishingContext())
    func schemaContextAndTypeInvariant() async throws {
        let elements: [(String, StructuredData)] = [
            ("Thing", StructuredData("Thing")),
            ("Organization", .organization(name: "O", url: "https://o.com")),
            ("WebSite", .webSite(name: "S", url: "https://s.com")),
            ("Event", .event(
                name: "E", startDate: "2026-01-01", endDate: "2026-01-02",
                locationName: "V", locality: "C", region: "S", postalCode: "0"
            ))
        ]

        for (expectedType, element) in elements {
            let output = element.markupString()
            #expect(output.contains("\"@context\" : \"https://schema.org\""),
                    "Missing @context in \(expectedType)")
            #expect(output.contains("\"@type\" : \"\(expectedType)\""),
                    "Missing @type in \(expectedType)")
        }
    }

    @Test("Article schema always includes headline, datePublished, and url",
          .publishingContext())
    func articleRequiredFieldsInvariant() async throws {
        let testCases: [(String, [String: any Sendable])] = [
            ("Minimal Article", [:]),
            ("Article With Author", ["author": "Jane"]),
            ("Article With Image", ["image": "/img.jpg"]),
            ("Article With Description", [:])
        ]

        for (title, metadata) in testCases {
            let article = makeArticle(title: title, metadata: metadata)
            let output = withArticleContext(article: article) {
                StructuredData.article().markupString()
            }

            #expect(output.contains("\"headline\" : \"\(title)\""),
                    "Missing headline for: \(title)")
            #expect(output.contains("\"datePublished\""),
                    "Missing datePublished for: \(title)")
            #expect(output.contains("\"url\""),
                    "Missing url for: \(title)")
        }
    }

    @Test("Empty outputs are truly empty strings", .publishingContext())
    func emptyOutputInvariant() async throws {
        // Article with no title
        let emptyArticle = StructuredData.article()
        #expect(emptyArticle.markupString().isEmpty)

        // Empty raw JSON
        let emptyJSON = StructuredData(json: "")
        #expect(emptyJSON.markupString().isEmpty)

        // Breadcrumbs on homepage
        let homepageOutput = withPageContext(
            pageURL: URL(string: "https://www.example.com/")!
        ) {
            StructuredData.breadcrumbs().markupString()
        }
        #expect(homepageOutput.isEmpty)
    }

    // MARK: - Stress Tests

    @Test("Large property dictionary renders without error", .publishingContext())
    @available(macOS 14.0, *)
    func largePropertyDictionary() async throws {
        var properties: [String: Any] = [:]
        for i in 0..<500 {
            properties["field_\(i)"] = "value_\(i)"
        }

        let element = StructuredData("Thing", properties: properties)
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Thing\""))
        #expect(output.contains("\"field_0\" : \"value_0\""))
        #expect(output.contains("\"field_499\" : \"value_499\""))
    }

    @Test("Long string values render correctly", .publishingContext())
    func longStringValues() async throws {
        let longDescription = String(repeating: "word ", count: 2000).trimmingCharacters(in: .whitespaces)
        let element = StructuredData("Article", properties: [
            "name": "Test",
            "description": longDescription
        ])
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Article\""))
        #expect(output.contains(longDescription))
    }

    @Test("Multiple sameAs URLs render correctly", .publishingContext())
    func manySameAsURLs() async throws {
        let urls = (0..<50).map { "https://platform\($0).example.com/profile" }
        let element = StructuredData.organization(
            name: "Well-Connected Org",
            url: "https://org.com",
            sameAs: urls
        )
        let output = element.markupString()

        #expect(output.contains("\"sameAs\""))
        #expect(output.contains("https://platform0.example.com/profile"))
        #expect(output.contains("https://platform49.example.com/profile"))
    }

    // MARK: - Documentation Example Verification

    @Test("Documentation example: generic LocalBusiness", .publishingContext())
    func docExampleGeneric() async throws {
        let element = StructuredData("LocalBusiness", properties: [
            "name": "Joe's Pizza",
            "telephone": "555-0123"
        ])
        let output = element.markupString()

        #expect(!output.isEmpty)
        #expect(output.contains("\"@type\" : \"LocalBusiness\""))
    }

    @Test("Documentation example: convenience methods", .publishingContext())
    func docExampleConvenience() async throws {
        let org = StructuredData.organization(name: "Acme", url: "https://acme.com")
        #expect(!org.markupString().isEmpty)

        let crumbs = StructuredData.breadcrumbs()
        _ = crumbs.markupString()

        let article = StructuredData.article()
        _ = article.markupString()
    }

    @Test("Documentation example: raw JSON", .publishingContext())
    func docExampleRawJSON() async throws {
        let customJSONString = """
        {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[]}
        """
        let element = StructuredData(json: customJSONString)
        let output = element.markupString()

        #expect(!output.isEmpty)
        #expect(output.contains("FAQPage"))
    }

    // MARK: - @graph Tests

    @Test("Graph wraps nodes in single @graph array", .publishingContext())
    func graphWrapsNodes() async throws {
        let nodes: [[String: Any]] = [
            ["@type": "Person", "@id": "https://example.com/#person", "name": "Jane"],
            ["@type": "WebSite", "@id": "https://example.com/#website", "name": "Jane's Site"]
        ]
        let element = StructuredData.graph(nodes: nodes)
        let output = element.markupString()

        #expect(output.contains("<script type=\"application/ld+json\">"))
        #expect(output.contains("</script>"))
        #expect(output.contains("\"@context\" : \"https://schema.org\""))
        #expect(output.contains("\"@graph\""))
        #expect(output.contains("\"@type\" : \"Person\""))
        #expect(output.contains("\"@type\" : \"WebSite\""))
        #expect(output.contains("\"@id\" : \"https://example.com/#person\""))
    }

    @Test("Graph produces exactly one script tag", .publishingContext())
    func graphSingleScriptTag() async throws {
        let nodes: [[String: Any]] = [
            ["@type": "Person", "name": "A"],
            ["@type": "WebSite", "name": "B"],
            ["@type": "WebPage", "name": "C"]
        ]
        let element = StructuredData.graph(nodes: nodes)
        let output = element.markupString()

        let scriptCount = output.components(separatedBy: "<script").count - 1
        #expect(scriptCount == 1)
    }

    @Test("Graph with empty nodes produces no output", .publishingContext())
    func graphEmptyNodes() async throws {
        let element = StructuredData.graph(nodes: [])
        let output = element.markupString()

        #expect(output.isEmpty)
    }

    @Test("Graph does not add @context to individual nodes", .publishingContext())
    func graphNoPerNodeContext() async throws {
        let nodes: [[String: Any]] = [
            ["@type": "Person", "name": "Jane"]
        ]
        let element = StructuredData.graph(nodes: nodes)
        let output = element.markupString()

        let contextCount = output.components(separatedBy: "@context").count - 1
        #expect(contextCount == 1)
    }

    // MARK: - Node Builder Tests

    @Test("personNode builds Person with required fields", .publishingContext())
    func personNodeBasic() async throws {
        let node = StructuredData.personNode(
            name: "Jane Doe",
            url: "https://jane.example.com"
        )

        #expect(node["@type"] as? String == "Person")
        #expect(node["name"] as? String == "Jane Doe")
        #expect(node["url"] as? String == "https://jane.example.com")
    }

    @Test("personNode includes @id when provided", .publishingContext())
    func personNodeWithId() async throws {
        let node = StructuredData.personNode(
            name: "Jane",
            url: "https://jane.example.com",
            id: "https://jane.example.com/#person"
        )

        #expect(node["@id"] as? String == "https://jane.example.com/#person")
    }

    @Test("personNode includes sameAs links", .publishingContext())
    func personNodeWithSameAs() async throws {
        let links = ["https://twitter.com/jane", "https://github.com/jane"]
        let node = StructuredData.personNode(
            name: "Jane",
            url: "https://jane.example.com",
            sameAs: links
        )

        let sameAs = try #require(node["sameAs"] as? [String])
        #expect(sameAs.count == 2)
        #expect(sameAs.contains("https://twitter.com/jane"))
    }

    @Test("personNode omits sameAs when empty", .publishingContext())
    func personNodeNoSameAs() async throws {
        let node = StructuredData.personNode(
            name: "Jane",
            url: "https://jane.example.com"
        )

        #expect(node["sameAs"] == nil)
    }

    @Test("webSiteNode builds WebSite with required fields", .publishingContext())
    func webSiteNodeBasic() async throws {
        let node = StructuredData.webSiteNode(
            name: "My Site",
            url: "https://example.com"
        )

        #expect(node["@type"] as? String == "WebSite")
        #expect(node["name"] as? String == "My Site")
        #expect(node["url"] as? String == "https://example.com")
    }

    @Test("webSiteNode includes optional fields", .publishingContext())
    func webSiteNodeFull() async throws {
        let node = StructuredData.webSiteNode(
            name: "My Site",
            url: "https://example.com",
            description: "A great site",
            inLanguage: "en-US",
            publisherId: "https://example.com/#person",
            id: "https://example.com/#website"
        )

        #expect(node["@id"] as? String == "https://example.com/#website")
        #expect(node["description"] as? String == "A great site")
        #expect(node["inLanguage"] as? String == "en-US")
        let publisher = try #require(node["publisher"] as? [String: String])
        #expect(publisher["@id"] == "https://example.com/#person")
    }

    @Test("webSiteNode omits nil optional fields", .publishingContext())
    func webSiteNodeMinimal() async throws {
        let node = StructuredData.webSiteNode(
            name: "Site",
            url: "https://example.com"
        )

        #expect(node["description"] == nil)
        #expect(node["inLanguage"] == nil)
        #expect(node["publisher"] == nil)
        #expect(node["@id"] == nil)
    }

    @Test("webPageNode builds WebPage with required fields", .publishingContext())
    func webPageNodeBasic() async throws {
        let node = StructuredData.webPageNode(
            url: "https://example.com/about",
            title: "About"
        )

        #expect(node["@type"] as? String == "WebPage")
        #expect(node["url"] as? String == "https://example.com/about")
        #expect(node["name"] as? String == "About")
    }

    @Test("webPageNode includes cross-references", .publishingContext())
    func webPageNodeCrossRefs() async throws {
        let node = StructuredData.webPageNode(
            url: "https://example.com/about",
            title: "About",
            description: "About page",
            isPartOfId: "https://example.com/#website",
            breadcrumbId: "https://example.com/about#breadcrumb",
            id: "https://example.com/about#webpage"
        )

        #expect(node["@id"] as? String == "https://example.com/about#webpage")
        #expect(node["description"] as? String == "About page")
        let isPartOf = try #require(node["isPartOf"] as? [String: String])
        #expect(isPartOf["@id"] == "https://example.com/#website")
        let breadcrumb = try #require(node["breadcrumb"] as? [String: String])
        #expect(breadcrumb["@id"] == "https://example.com/about#breadcrumb")
    }

    @Test("profilePageNode builds ProfilePage type", .publishingContext())
    func profilePageNodeType() async throws {
        let node = StructuredData.profilePageNode(
            url: "https://example.com",
            title: "Home"
        )

        #expect(node["@type"] as? String == "ProfilePage")
        #expect(node["url"] as? String == "https://example.com")
        #expect(node["name"] as? String == "Home")
    }

    @Test("profilePageNode includes mainEntity reference", .publishingContext())
    func profilePageNodeMainEntity() async throws {
        let node = StructuredData.profilePageNode(
            url: "https://example.com",
            title: "Home",
            mainEntityId: "https://example.com/#person",
            id: "https://example.com/#profilepage"
        )

        let mainEntity = try #require(node["mainEntity"] as? [String: String])
        #expect(mainEntity["@id"] == "https://example.com/#person")
        #expect(node["@id"] as? String == "https://example.com/#profilepage")
    }

    @Test("collectionPageNode builds CollectionPage type", .publishingContext())
    func collectionPageNodeType() async throws {
        let node = StructuredData.collectionPageNode(
            url: "https://example.com/projects",
            title: "Projects"
        )

        #expect(node["@type"] as? String == "CollectionPage")
        #expect(node["name"] as? String == "Projects")
    }

    @Test("collectionPageNode includes cross-references", .publishingContext())
    func collectionPageNodeCrossRefs() async throws {
        let node = StructuredData.collectionPageNode(
            url: "https://example.com/projects",
            title: "Projects",
            isPartOfId: "https://example.com/#website",
            mainEntityId: "https://example.com/#person",
            id: "https://example.com/projects#collectionpage"
        )

        let isPartOf = try #require(node["isPartOf"] as? [String: String])
        #expect(isPartOf["@id"] == "https://example.com/#website")
        let mainEntity = try #require(node["mainEntity"] as? [String: String])
        #expect(mainEntity["@id"] == "https://example.com/#person")
    }

    @Test("articleNode builds Article with required fields", .publishingContext())
    func articleNodeBasic() async throws {
        let node = StructuredData.articleNode(
            headline: "Test Post",
            url: "https://example.com/blog/test",
            datePublished: "2026-01-15T00:00:00Z"
        )

        #expect(node["@type"] as? String == "Article")
        #expect(node["headline"] as? String == "Test Post")
        #expect(node["url"] as? String == "https://example.com/blog/test")
        #expect(node["datePublished"] as? String == "2026-01-15T00:00:00Z")
    }

    @Test("articleNode includes optional fields", .publishingContext())
    func articleNodeFull() async throws {
        let node = StructuredData.articleNode(
            headline: "Test Post",
            url: "https://example.com/blog/test",
            datePublished: "2026-01-15T00:00:00Z",
            dateModified: "2026-02-01T00:00:00Z",
            description: "A test post",
            image: "https://example.com/images/hero.jpg",
            authorId: "https://example.com/#person",
            publisherId: "https://example.com/#person",
            isPartOfId: "https://example.com/#website",
            id: "https://example.com/blog/test#article"
        )

        #expect(node["@id"] as? String == "https://example.com/blog/test#article")
        #expect(node["dateModified"] as? String == "2026-02-01T00:00:00Z")
        #expect(node["description"] as? String == "A test post")
        #expect(node["image"] as? String == "https://example.com/images/hero.jpg")
        let author = try #require(node["author"] as? [String: String])
        #expect(author["@id"] == "https://example.com/#person")
        let publisher = try #require(node["publisher"] as? [String: String])
        #expect(publisher["@id"] == "https://example.com/#person")
        let isPartOf = try #require(node["isPartOf"] as? [String: String])
        #expect(isPartOf["@id"] == "https://example.com/#website")
    }

    @Test("articleNode omits nil optional fields", .publishingContext())
    func articleNodeMinimal() async throws {
        let node = StructuredData.articleNode(
            headline: "Test",
            url: "https://example.com/test",
            datePublished: "2026-01-01T00:00:00Z"
        )

        #expect(node["dateModified"] == nil)
        #expect(node["description"] == nil)
        #expect(node["image"] == nil)
        #expect(node["author"] == nil)
        #expect(node["publisher"] == nil)
        #expect(node["@id"] == nil)
    }

    @Test("breadcrumbListNode builds BreadcrumbList", .publishingContext())
    func breadcrumbListNodeBasic() async throws {
        let node = StructuredData.breadcrumbListNode(
            siteURL: "https://example.com",
            pageURL: "https://example.com/about",
            pageTitle: "About"
        )

        #expect(node["@type"] as? String == "BreadcrumbList")
        let items = try #require(node["itemListElement"] as? [[String: Any]])
        #expect(items.count == 2)
        #expect(items[0]["position"] as? Int == 1)
        #expect(items[0]["name"] as? String == "Home")
        #expect(items[1]["position"] as? Int == 2)
        #expect(items[1]["name"] as? String == "About")
    }

    @Test("breadcrumbListNode includes @id when provided", .publishingContext())
    func breadcrumbListNodeWithId() async throws {
        let node = StructuredData.breadcrumbListNode(
            siteURL: "https://example.com",
            pageURL: "https://example.com/about",
            pageTitle: "About",
            homeName: "Start",
            id: "https://example.com/about#breadcrumb"
        )

        #expect(node["@id"] as? String == "https://example.com/about#breadcrumb")
        let items = try #require(node["itemListElement"] as? [[String: Any]])
        #expect(items[0]["name"] as? String == "Start")
    }

    @Test("Graph composed from node builders renders valid JSON-LD", .publishingContext())
    func graphFromNodeBuilders() async throws {
        let person = StructuredData.personNode(
            name: "Jane",
            url: "https://example.com",
            id: "https://example.com/#person"
        )
        let website = StructuredData.webSiteNode(
            name: "Jane's Site",
            url: "https://example.com",
            publisherId: "https://example.com/#person",
            id: "https://example.com/#website"
        )
        let page = StructuredData.profilePageNode(
            url: "https://example.com",
            title: "Home",
            mainEntityId: "https://example.com/#person",
            isPartOfId: "https://example.com/#website",
            id: "https://example.com/#profilepage"
        )

        let element = StructuredData.graph(nodes: [person, website, page])
        let output = element.markupString()

        #expect(output.contains("\"@graph\""))
        #expect(output.contains("\"@type\" : \"Person\""))
        #expect(output.contains("\"@type\" : \"WebSite\""))
        #expect(output.contains("\"@type\" : \"ProfilePage\""))
        #expect(output.contains("\"@id\" : \"https://example.com/#person\""))

        let scriptCount = output.components(separatedBy: "<script").count - 1
        #expect(scriptCount == 1)
    }
}
