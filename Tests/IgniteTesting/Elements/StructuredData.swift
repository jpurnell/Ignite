//
// StructuredData.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Testing

@testable import Ignite

/// Tests for the `StructuredData` element.
@Suite("StructuredData Tests")
@MainActor class StructuredDataTests: IgniteTestSuite {
    static let sites: [any Site] = [TestSite(), TestSubsite()]

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

    @Test("Organization convenience method", arguments: await Self.sites)
    func organization(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData.organization(
            name: "Acme Corp",
            url: "https://acme.com",
            description: "A test company",
            foundingDate: "2000-01-01",
            sameAs: ["https://twitter.com/acme"],
            parentOrganization: (name: "Parent Inc", url: "https://parent.com")
        )
        let output = element.markupString()

        #expect(output.contains("\"@type\" : \"Organization\""))
        #expect(output.contains("\"name\" : \"Acme Corp\""))
        #expect(output.contains("\"url\" : \"https://acme.com\""))
        #expect(output.contains("\"description\" : \"A test company\""))
        #expect(output.contains("\"foundingDate\" : \"2000-01-01\""))
        #expect(output.contains("\"https://twitter.com/acme\""))
        #expect(output.contains("\"name\" : \"Parent Inc\""))
    }

    @Test("WebSite convenience method", arguments: await Self.sites)
    func webSite(for site: any Site) async throws {
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

    @Test("Event convenience method", arguments: await Self.sites)
    func event(for site: any Site) async throws {
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
        #expect(output.contains("\"https://schema.org/OfflineEventAttendanceMode\""))
        #expect(output.contains("\"https://schema.org/EventScheduled\""))
        #expect(output.contains("\"name\" : \"Org Co\""))
    }

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

    @Test("Article emits nothing on non-article pages", arguments: await Self.sites)
    func articleNonArticlePage(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData.article(
            publisher: "Test Publisher",
            publisherURL: "https://publisher.com"
        )
        let output = element.markupString()

        // On a non-article page (empty article title), should emit nothing
        #expect(output.isEmpty)
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

    @Test("Empty properties still renders valid JSON-LD", arguments: await Self.sites)
    func emptyProperties(for site: any Site) async throws {
        try PublishingContext.initialize(for: site, from: #filePath)

        let element = StructuredData("Thing")
        let output = element.markupString()

        #expect(output.contains("\"@context\" : \"https://schema.org\""))
        #expect(output.contains("\"@type\" : \"Thing\""))
    }
}
