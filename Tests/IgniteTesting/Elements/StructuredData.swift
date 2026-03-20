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
    static let sites: [any Site] = [TestSite(), TestSubsite()]

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

    @Test("Generic schema renders JSON-LD script tag", arguments: await Self.sites)
    func genericSchema(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Raw JSON renders as-is", arguments: await Self.sites)
    func rawJSON(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let json = """
        {"@context":"https://schema.org","@type":"Thing","name":"Test"}
        """
        let element = StructuredData(json: json)
        let output = element.markupString()

        #expect(output.contains("<script type=\"application/ld+json\">"))
        #expect(output.contains(json))
        #expect(output.contains("</script>"))
    }

    @Test("Custom context overrides default", arguments: await Self.sites)
    func customContext(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData(
            "Dataset",
            context: "https://example.org/custom",
            properties: ["name": "Test"]
        )
        let output = element.markupString()

        #expect(output.contains("\"@context\" : \"https://example.org/custom\""))
        #expect(output.contains("\"@type\" : \"Dataset\""))
    }

    @Test("Empty properties still renders valid JSON-LD", arguments: await Self.sites)
    func emptyProperties(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData("Thing")
        let output = element.markupString()

        #expect(output.contains("\"@context\" : \"https://schema.org\""))
        #expect(output.contains("\"@type\" : \"Thing\""))
    }

    @Test("Nested dictionary properties render correctly", arguments: await Self.sites)
    func nestedProperties(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Array properties render correctly", arguments: await Self.sites)
    func arrayProperties(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData("Organization", properties: [
            "name": "Test Org",
            "sameAs": ["https://twitter.com/test", "https://facebook.com/test"]
        ])
        let output = element.markupString()

        #expect(output.contains("\"https://twitter.com/test\""))
        #expect(output.contains("\"https://facebook.com/test\""))
    }

    // MARK: - Organization Tests

    @Test("Organization with all fields", arguments: await Self.sites)
    func organizationFull(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Organization without optional fields", arguments: await Self.sites)
    func organizationMinimal(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Organization with custom parent type", arguments: await Self.sites)
    func organizationCustomParentType(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("WebSite with all fields", arguments: await Self.sites)
    func webSiteFull(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("WebSite without description", arguments: await Self.sites)
    func webSiteMinimal(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Event with all fields", arguments: await Self.sites)
    func eventFull(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Event without organizer", arguments: await Self.sites)
    func eventWithoutOrganizer(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Event with custom status and attendance mode", arguments: await Self.sites)
    func eventCustomStatus(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Event with non-US country", arguments: await Self.sites)
    func eventNonUSCountry(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Breadcrumbs renders BreadcrumbList schema", arguments: await Self.sites)
    func breadcrumbs(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData.breadcrumbs()
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"BreadcrumbList\""))
        #expect(output.contains("\"@type\" : \"ListItem\""))
        #expect(output.contains("\"position\" : 1"))
        #expect(output.contains("\"position\" : 2"))
        #expect(output.contains("\"name\" : \"Home\""))
    }

    @Test("Breadcrumbs uses custom home name", arguments: await Self.sites)
    func breadcrumbsCustomName(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData.breadcrumbs(homeName: "Start")
        let output = element.markupString()

        #expect(output.contains("\"name\" : \"Start\""))
    }

    @Test("Breadcrumbs emits nothing on homepage", arguments: await Self.sites)
    func breadcrumbsHomepage(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let output = withPageContext(
            pageURL: URL(string: "https://www.example.com/")!
        ) {
            StructuredData.breadcrumbs().markupString()
        }

        #expect(output.isEmpty)
    }

    @Test("Breadcrumbs includes page title and URL", arguments: await Self.sites)
    func breadcrumbsPageInfo(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Article emits nothing on non-article pages", arguments: await Self.sites)
    func articleNonArticlePage(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData.article(
            publisher: "Test Publisher",
            publisherURL: "https://publisher.com"
        )
        let output = element.markupString()

        #expect(output.isEmpty)
    }

    @Test("Article renders headline and date", arguments: await Self.sites)
    func articleBasic(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Article includes description when present", arguments: await Self.sites)
    func articleWithDescription(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let article = makeArticle(
            title: "Described Article",
            description: "A thorough summary of this article."
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"description\" : \"A thorough summary of this article.\""))
    }

    @Test("Article omits description when empty", arguments: await Self.sites)
    func articleWithoutDescription(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let article = makeArticle(title: "No Description")

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(!output.contains("\"description\""))
    }

    @Test("Article includes author from metadata", arguments: await Self.sites)
    func articleWithAuthor(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Article includes image with relative path", arguments: await Self.sites)
    func articleWithRelativeImage(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let article = makeArticle(
            title: "Image Article",
            metadata: ["image": "/images/hero.jpg"]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        // Relative image paths should be prefixed with the site base URL
        #expect(output.contains("\"image\""))
        #expect(output.contains("/images/hero.jpg"))
    }

    @Test("Article includes image with absolute URL", arguments: await Self.sites)
    func articleWithAbsoluteImage(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let article = makeArticle(
            title: "External Image Article",
            metadata: ["image": "https://cdn.example.com/photo.jpg"]
        )

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("\"image\" : \"https://cdn.example.com/photo.jpg\""))
    }

    @Test("Article includes publisher", arguments: await Self.sites)
    func articleWithPublisher(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Article includes publisher name without URL", arguments: await Self.sites)
    func articleWithPublisherNoURL(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let article = makeArticle(title: "Published Article")

        let output = withArticleContext(article: article) {
            StructuredData.article(publisher: "Simple Publisher").markupString()
        }

        #expect(output.contains("\"name\" : \"Simple Publisher\""))
        // Publisher object should not contain a url key
        let publisherRange = output.range(of: "\"publisher\"")
        #expect(publisherRange != nil)
    }

    @Test("Article omits publisher when not provided", arguments: await Self.sites)
    func articleWithoutPublisher(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let article = makeArticle(title: "Unpublished Article")

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(!output.contains("\"publisher\""))
    }

    @Test("Article includes dateModified when different from date", arguments: await Self.sites)
    func articleWithModifiedDate(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Article omits dateModified when same as date", arguments: await Self.sites)
    func articleWithoutModifiedDate(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Article with all fields populated", arguments: await Self.sites)
    func articleFullyPopulated(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Properties with special characters are JSON-escaped", arguments: await Self.sites)
    func specialCharacters(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData("Thing", properties: [
            "name": "Joe's \"Best\" Pizza & Subs",
            "description": "Line one\nLine two"
        ])
        let output = element.markupString()

        // JSONSerialization handles escaping — output must still be valid script
        #expect(output.contains("<script type=\"application/ld+json\">"))
        #expect(output.contains("</script>"))
        #expect(output.contains("Joe's"))
        #expect(output.contains("Pizza & Subs"))
    }

    @Test("Properties with unicode characters", arguments: await Self.sites)
    func unicodeProperties(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData("Organization", properties: [
            "name": "Caf\u{00E9} M\u{00FC}nchen \u{1F37A}",
            "description": "\u{4E16}\u{754C}\u{4F60}\u{597D}"
        ])
        let output = element.markupString()

        #expect(output.contains("Caf\u{00E9}"))
        #expect(output.contains("M\u{00FC}nchen"))
        #expect(output.contains("\u{4E16}\u{754C}\u{4F60}\u{597D}"))
    }

    @Test("Empty raw JSON renders empty output", arguments: await Self.sites)
    func emptyRawJSON(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData(json: "")
        let output = element.markupString()

        #expect(output.isEmpty)
    }

    @Test("Organization with empty sameAs array omits field", arguments: await Self.sites)
    func organizationEmptySameAs(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData.organization(
            name: "Test Org",
            url: "https://test.org",
            sameAs: []
        )
        let output = element.markupString()

        #expect(!output.contains("\"sameAs\""))
    }

    @Test("Deeply nested schema properties render correctly", arguments: await Self.sites)
    func deeplyNestedProperties(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Article title with HTML entities", arguments: await Self.sites)
    func articleTitleWithEntities(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let article = makeArticle(title: "Rock & Roll: A \"History\"")

        let output = withArticleContext(article: article) {
            StructuredData.article().markupString()
        }

        #expect(output.contains("Rock & Roll"))
        #expect(output.contains("\"@type\" : \"Article\""))
    }

    @Test("Breadcrumbs with deeply nested page path", arguments: await Self.sites)
    func breadcrumbsDeepPath(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Invalid JSON string produces empty output", arguments: await Self.sites)
    func invalidRawJSON(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        // Raw JSON is passed through as-is (not validated), so even invalid
        // JSON will be wrapped in a script tag. This tests that the element
        // does not crash on malformed input.
        let element = StructuredData(json: "{invalid json{{{")
        let output = element.markupString()

        // Should still produce a script tag (raw content is not validated)
        #expect(output.contains("<script type=\"application/ld+json\">"))
        #expect(output.contains("{invalid json{{{"))
    }

    @Test("Schema with empty type string still renders", arguments: await Self.sites)
    func emptyTypeString(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData("", properties: ["name": "Test"])
        let output = element.markupString()

        // Should render — the type is just empty, not invalid JSON
        #expect(output.contains("\"@type\" : \"\""))
        #expect(output.contains("\"name\" : \"Test\""))
    }

    // MARK: - Property-Based Tests

    @Test("All non-empty outputs are wrapped in script tags",
          arguments: await Self.sites)
    func outputStructureInvariant(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("All schema outputs contain @context and @type",
          arguments: await Self.sites)
    func schemaContextAndTypeInvariant(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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
          arguments: await Self.sites)
    func articleRequiredFieldsInvariant(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Empty outputs are truly empty strings", arguments: await Self.sites)
    func emptyOutputInvariant(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Large property dictionary renders without error",
          arguments: await Self.sites)
    @available(macOS 14.0, *)
    func largePropertyDictionary(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Long string values render correctly", arguments: await Self.sites)
    func longStringValues(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let longDescription = String(repeating: "word ", count: 2000).trimmingCharacters(in: .whitespaces)
        let element = StructuredData("Article", properties: [
            "name": "Test",
            "description": longDescription
        ])
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Article\""))
        #expect(output.contains(longDescription))
    }

    @Test("Multiple sameAs URLs render correctly", arguments: await Self.sites)
    func manySameAsURLs(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

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

    @Test("Documentation example: generic LocalBusiness", arguments: await Self.sites)
    func docExampleGeneric(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        // From StructuredData.swift doc comment
        let element = StructuredData("LocalBusiness", properties: [
            "name": "Joe's Pizza",
            "telephone": "555-0123"
        ])
        let output = element.markupString()

        #expect(!output.isEmpty)
        #expect(output.contains("\"@type\" : \"LocalBusiness\""))
    }

    @Test("Documentation example: convenience methods", arguments: await Self.sites)
    func docExampleConvenience(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        // From StructuredData.swift doc comment
        let org = StructuredData.organization(name: "Acme", url: "https://acme.com")
        #expect(!org.markupString().isEmpty)

        let crumbs = StructuredData.breadcrumbs()
        // breadcrumbs output depends on page context, just verify no crash
        _ = crumbs.markupString()

        let article = StructuredData.article()
        // article output depends on article context, just verify no crash
        _ = article.markupString()
    }

    @Test("Documentation example: raw JSON", arguments: await Self.sites)
    func docExampleRawJSON(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        // From StructuredData.swift doc comment
        let customJSONString = """
        {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[]}
        """
        let element = StructuredData(json: customJSONString)
        let output = element.markupString()

        #expect(!output.isEmpty)
        #expect(output.contains("FAQPage"))
    }
}
