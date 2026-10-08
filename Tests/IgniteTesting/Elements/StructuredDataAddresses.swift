//
// StructuredDataAddresses.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that the addresses in structured data stand on their own.
///
/// JSON-LD is read by crawlers away from the page it came from, so `url`, `image`,
/// `sameAs`, `item` and `@id` have to be absolute. A path is completed with the
/// address of the site being published; an address that is already absolute is left
/// exactly as it was written.
@Suite("StructuredData Address Tests")
struct StructuredDataAddressTests {
    private static let subsite = "https://www.example.com/subsite"

    private func onSubsite<T>(_ operation: () throws -> T) throws -> T {
        try PublishingContext.withInitialized(for: TestSubsite(), from: #filePath) { _ in try operation() }
    }

    private func onRootSite<T>(_ operation: () throws -> T) throws -> T {
        try PublishingContext.withInitialized(for: TestSite(), from: #filePath) { _ in try operation() }
    }

    // MARK: - Elements

    @Test("An organization's addresses are completed with the site's address")
    func organization() throws {
        let output = try onSubsite {
            StructuredData.organization(
                name: "Acme",
                url: "/",
                sameAs: ["https://social.example/acme", "/press"],
                parentOrganization: (name: "Parent", url: "/parent")
            ).markupString()
        }

        #expect(output == """
        <script type="application/ld+json">
        {
          "@context" : "https://schema.org",
          "@type" : "Organization",
          "name" : "Acme",
          "parentOrganization" : {
            "@type" : "Organization",
            "name" : "Parent",
            "url" : "https://www.example.com/subsite/parent"
          },
          "sameAs" : [
            "https://social.example/acme",
            "https://www.example.com/subsite/press"
          ],
          "url" : "https://www.example.com/subsite/"
        }
        </script>
        """)
    }

    @Test("An organization with absolute addresses is written exactly as before")
    func organizationAlreadyAbsolute() throws {
        let output = try onSubsite {
            StructuredData.organization(
                name: "Acme",
                url: "https://acme.example",
                sameAs: ["https://social.example/acme"],
                parentOrganization: (name: "Parent", url: "https://parent.example/")
            ).markupString()
        }

        #expect(output == """
        <script type="application/ld+json">
        {
          "@context" : "https://schema.org",
          "@type" : "Organization",
          "name" : "Acme",
          "parentOrganization" : {
            "@type" : "Organization",
            "name" : "Parent",
            "url" : "https://parent.example/"
          },
          "sameAs" : [
            "https://social.example/acme"
          ],
          "url" : "https://acme.example"
        }
        </script>
        """)
    }

    @Test("A web site's address is completed")
    func webSite() throws {
        let output = try onRootSite { StructuredData.webSite(name: "Site", url: "/").markupString() }
        #expect(output == """
        <script type="application/ld+json">
        {
          "@context" : "https://schema.org",
          "@type" : "WebSite",
          "name" : "Site",
          "url" : "https://www.example.com/"
        }
        </script>
        """)
    }

    @Test("An event organizer's address is completed")
    func eventOrganizer() throws {
        let output = try onSubsite {
            StructuredData.event(
                name: "Launch", startDate: "2026-01-01", endDate: "2026-01-02", locationName: "Hall",
                locality: "Town", region: "CA", postalCode: "90000",
                organizer: (name: "Acme", url: "/about")
            ).markupString()
        }
        #expect(output.contains("""
          "organizer" : {
            "@type" : "Organization",
            "name" : "Acme",
            "url" : "https://www.example.com/subsite/about"
          },
        """))
    }

    @Test("An article's publisher address is completed")
    func articlePublisher() throws {
        let output = try onSubsite {
            var article = Article()
            article.title = "Story"
            article.metadata = ["date": Date(timeIntervalSince1970: 0)]
            var environment = EnvironmentValues()
            environment.article = article
            environment.page = PageMetadata(
                title: "Story", description: "", url: URL(static: "https://www.example.com/subsite/story"))
            return PublishingContext.shared.withEnvironment(environment) {
                StructuredData.article(publisher: "Acme", publisherURL: "/about").markupString()
            }
        }
        #expect(output.contains("""
          "publisher" : {
            "@type" : "Organization",
            "name" : "Acme",
            "url" : "https://www.example.com/subsite/about"
          },
        """))
    }

    // MARK: - Node builders

    @Test("A person node's addresses and ID are completed")
    func personNode() throws {
        let node = try onSubsite {
            StructuredData.personNode(
                name: "Jo", url: "/about", sameAs: ["/jo", "https://social.example/jo"], id: "#person")
        }
        #expect(node["url"] as? String == "\(Self.subsite)/about")
        #expect(node["sameAs"] as? [String] == ["\(Self.subsite)/jo", "https://social.example/jo"])
        #expect(node["@id"] as? String == "\(Self.subsite)/#person")
    }

    @Test("A web site node's address, ID and publisher reference are completed")
    func webSiteNode() throws {
        let node = try onSubsite {
            StructuredData.webSiteNode(name: "Site", url: "/", publisherId: "#person", id: "#website")
        }
        #expect(node["url"] as? String == "\(Self.subsite)/")
        #expect(node["@id"] as? String == "\(Self.subsite)/#website")
        #expect(node["publisher"] as? [String: String] == ["@id": "\(Self.subsite)/#person"])
    }

    @Test("A web page node's address, ID and references are completed")
    func webPageNode() throws {
        let node = try onSubsite {
            StructuredData.webPageNode(
                url: "/about", title: "About", isPartOfId: "#website",
                breadcrumbId: "/about#breadcrumb", id: "/about#webpage")
        }
        #expect(node["url"] as? String == "\(Self.subsite)/about")
        #expect(node["@id"] as? String == "\(Self.subsite)/about#webpage")
        #expect(node["isPartOf"] as? [String: String] == ["@id": "\(Self.subsite)/#website"])
        #expect(node["breadcrumb"] as? [String: String] == ["@id": "\(Self.subsite)/about#breadcrumb"])
    }

    @Test("A profile page node's address, ID and references are completed")
    func profilePageNode() throws {
        let node = try onSubsite {
            StructuredData.profilePageNode(
                url: "/me", title: "Me", mainEntityId: "#person", isPartOfId: "#website", id: "/me#page")
        }
        #expect(node["url"] as? String == "\(Self.subsite)/me")
        #expect(node["@id"] as? String == "\(Self.subsite)/me#page")
        #expect(node["mainEntity"] as? [String: String] == ["@id": "\(Self.subsite)/#person"])
        #expect(node["isPartOf"] as? [String: String] == ["@id": "\(Self.subsite)/#website"])
    }

    @Test("A collection page node's address, ID and references are completed")
    func collectionPageNode() throws {
        let node = try onSubsite {
            StructuredData.collectionPageNode(
                url: "/blog", title: "Blog", isPartOfId: "#website", mainEntityId: "#list", id: "/blog#page")
        }
        #expect(node["url"] as? String == "\(Self.subsite)/blog")
        #expect(node["@id"] as? String == "\(Self.subsite)/blog#page")
        #expect(node["mainEntity"] as? [String: String] == ["@id": "\(Self.subsite)/#list"])
        #expect(node["isPartOf"] as? [String: String] == ["@id": "\(Self.subsite)/#website"])
    }

    @Test("An article node's address, image, ID and references are completed")
    func articleNode() throws {
        let node = try onSubsite {
            StructuredData.articleNode(
                headline: "Story", url: "/story", datePublished: "2026-01-01", image: "/images/story.png",
                authorId: "#person", publisherId: "#org", isPartOfId: "/story#webpage", id: "/story#article")
        }
        #expect(node["url"] as? String == "\(Self.subsite)/story")
        #expect(node["image"] as? String == "\(Self.subsite)/images/story.png")
        #expect(node["@id"] as? String == "\(Self.subsite)/story#article")
        #expect(node["author"] as? [String: String] == ["@id": "\(Self.subsite)/#person"])
        #expect(node["publisher"] as? [String: String] == ["@id": "\(Self.subsite)/#org"])
        #expect(node["isPartOf"] as? [String: String] == ["@id": "\(Self.subsite)/story#webpage"])
    }

    @Test("A breadcrumb list node's items and ID are completed")
    func breadcrumbListNode() throws {
        let node = try onSubsite {
            StructuredData.breadcrumbListNode(
                siteURL: "/", pageURL: "/about", pageTitle: "About", id: "/about#breadcrumb")
        }
        let items = try #require(node["itemListElement"] as? [[String: Any]])
        #expect(items.map { $0["item"] as? String } == ["\(Self.subsite)/", "\(Self.subsite)/about"])
        #expect(node["@id"] as? String == "\(Self.subsite)/about#breadcrumb")
    }

    @Test("A graph of nodes with site paths is written with absolute addresses")
    func graph() throws {
        let output = try onRootSite {
            StructuredData.graph(nodes: [
                StructuredData.webSiteNode(name: "Site", url: "/", id: "#website"),
                StructuredData.webPageNode(url: "/about", title: "About", isPartOfId: "#website")
            ]).markupString()
        }
        #expect(output == """
        <script type="application/ld+json">
        {
          "@context" : "https://schema.org",
          "@graph" : [
            {
              "@id" : "https://www.example.com/#website",
              "@type" : "WebSite",
              "name" : "Site",
              "url" : "https://www.example.com/"
            },
            {
              "@type" : "WebPage",
              "isPartOf" : {
                "@id" : "https://www.example.com/#website"
              },
              "name" : "About",
              "url" : "https://www.example.com/about"
            }
          ]
        }
        </script>
        """)
    }

    // MARK: - What is left alone

    @Test("Addresses that are already absolute are left exactly as written", arguments: [
        "https://example.com/about", "https://example.com/about/", "https://example.com/#org",
        "urn:uuid:6e8bc430-9c3a-11d9-9669-0800200c9a66", "mailto:me@example.com"
    ])
    func absoluteAddressesUnchanged(address: String) throws {
        let node = try onSubsite {
            StructuredData.personNode(name: "Jo", url: address, sameAs: [address], id: address)
        }
        #expect(node["url"] as? String == address)
        #expect(node["sameAs"] as? [String] == [address])
        #expect(node["@id"] as? String == address)
    }

    @Test("A protocol-relative address is given the site's scheme")
    func protocolRelative() throws {
        let node = try onSubsite { StructuredData.personNode(name: "Jo", url: "//cdn.example.com/jo") }
        #expect(node["url"] as? String == "https://cdn.example.com/jo")
    }

    @Test("A blank node identifier is not an address and is left alone")
    func blankNodeIdentifier() throws {
        let node = try onSubsite {
            StructuredData.webSiteNode(name: "Site", url: "/", publisherId: "_:publisher", id: "_:site")
        }
        #expect(node["@id"] as? String == "_:site")
        #expect(node["publisher"] as? [String: String] == ["@id": "_:publisher"])
    }

    @Test("An empty address stays empty")
    func emptyAddress() throws {
        let node = try onSubsite { StructuredData.personNode(name: "Jo", url: "") }
        #expect(node["url"] as? String == "")
    }

    @Test("With no site being published there is nothing to complete an address with")
    func outsideAPublish() {
        #expect(PublishingContext.current == nil)
        let node = StructuredData.personNode(name: "Jo", url: "/about", id: "#person")
        #expect(node["url"] as? String == "/about")
        #expect(node["@id"] as? String == "#person")
    }

    @Test("The generic initializer writes properties as they are given")
    func genericInitializerUnchanged() throws {
        let output = try onSubsite { StructuredData("Thing", properties: ["url": "/about"]).markupString() }
        #expect(output.contains(#""url" : "/about""#))
    }
}
