//
// Analytics.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `Analytics` snippet generation.
@Suite("Analytics Tests")
struct AnalyticsTests {
    @Test("Google Analytics produces correct script", .publishingContext())
    func googleAnalytics() {
        let analytics = Analytics(.googleAnalytics(measurementID: "GA-12345"))
        let output = analytics.googleAnalyticsCode(for: "GA-12345")

        #expect(output == """
        <!-- Google Analytics 4 -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=GA-12345"></script>
        <script>
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'GA-12345');
        </script>
        """)
    }

    @Test("Fathom produces correct script", .publishingContext())
    func fathom() {
        let analytics = Analytics(.fathom(siteID: "ABCDE"))
        let output = analytics.fathomCode(for: "ABCDE")

        #expect(output == """
        <!-- Fathom Analytics -->
        <script src="https://cdn.usefathom.com/script.js" data-site="ABCDE" defer></script>
        """)
    }

    @Test("Clicky produces correct script", .publishingContext())
    func clicky() {
        let analytics = Analytics(.clicky(siteID: "12345"))
        let output = analytics.clickyCode(for: "12345")

        #expect(output == """
        <!-- Clicky Analytics -->
        <script>var clicky_site_ids = clicky_site_ids || []; clicky_site_ids.push(12345);</script>
        <script async src="//static.getclicky.com/js"></script>
        """)
    }

    @Test("TelemetryDeck produces correct script", .publishingContext())
    func telemetryDeck() {
        let analytics = Analytics(.telemetryDeck(siteID: "ABC-123"))
        let output = analytics.telemetryDeckCode(for: "ABC-123")

        #expect(output == """
        <!-- TelemetryDeck Analytics -->
        <script
            src="https://cdn.telemetrydeck.com/websdk/telemetrydeck.min.js"
            data-app-id="ABC-123"
        ></script>
        """)
    }

    @Test("Plausible with no measurements produces base script", .publishingContext())
    func plausibleNoMeasurements() {
        let analytics = Analytics(.plausible(domain: "example.com"))
        let output = analytics.plausibleCode(for: "example.com", using: [])

        #expect(output == """
        <!-- Plausible Analytics -->
        <script defer data-domain="example.com" src="https://plausible.io/js/script.js"></script>
        """)
    }

    @Test("Plausible with single measurement includes it in URL", .publishingContext())
    func plausibleSingleMeasurement() {
        let analytics = Analytics(.plausible(domain: "example.com", measurements: [.hash]))
        let output = analytics.plausibleCode(for: "example.com", using: [.hash])

        #expect(output == """
        <!-- Plausible Analytics -->
        <script defer data-domain="example.com" src="https://plausible.io/js/script.hash.js"></script>
        """)
    }

    @Test("Plausible with multiple measurements sorts them alphabetically", .publishingContext())
    func plausibleMultipleMeasurementsSorted() {
        let measurements: Set<Analytics.PlausibleMeasurement> = [.outboundLinks, .hash]
        let analytics = Analytics(.plausible(domain: "example.com", measurements: measurements))
        let output = analytics.plausibleCode(for: "example.com", using: measurements)

        #expect(output == """
        <!-- Plausible Analytics -->
        <script defer data-domain="example.com" src="https://plausible.io/js/script.hash.outbound-links.js"></script>
        """)
    }

    @Test("Plausible with track404 adds separate script block", .publishingContext())
    func plausibleTrack404() {
        let measurements: Set<Analytics.PlausibleMeasurement> = [.track404]
        let analytics = Analytics(.plausible(domain: "example.com", measurements: measurements))
        let output = analytics.plausibleCode(for: "example.com", using: measurements)

        #expect(output.contains("src=\"https://plausible.io/js/script.js\""))
        #expect(output.contains("window.plausible = window.plausible || function()"))
        #expect(output.contains("window.plausible.q"))
    }

    @Test("Plausible with track404 and other measurements combines correctly", .publishingContext())
    func plausibleTrack404WithOtherMeasurements() {
        let measurements: Set<Analytics.PlausibleMeasurement> = [.track404, .hash, .revenue]
        let analytics = Analytics(.plausible(domain: "example.com", measurements: measurements))
        let output = analytics.plausibleCode(for: "example.com", using: measurements)

        #expect(output.contains("src=\"https://plausible.io/js/script.hash.revenue.js\""))
        #expect(output.contains("window.plausible = window.plausible || function()"))
    }

    @Test("Plausible all measurements produce deterministic order", .publishingContext())
    func plausibleAllMeasurementsSorted() {
        let all: Set<Analytics.PlausibleMeasurement> = [
            .fileDownloads, .hash, .outboundLinks,
            .pageviewProps, .revenue, .taggedEvents
        ]
        let analytics = Analytics(.plausible(domain: "example.com", measurements: all))
        let output = analytics.plausibleCode(for: "example.com", using: all)

        let expected = "script.file-downloads.hash.outbound-links.pageview-props.revenue.tagged-events.js"
        #expect(output.contains(expected))
    }

    // MARK: - Hostile identifiers

    /// An identifier that ends an attribute and a script element if written as-is.
    private static let hostile = #"x"></script><script>alert(1)//"#

    /// `hostile`, escaped for a double-quoted attribute.
    private static let hostileAttribute = "x&quot;&gt;&lt;/script&gt;&lt;script&gt;alert(1)//"

    @Test("A Clicky site ID that is not a number is written as a string, not as code", .publishingContext())
    func clickyNonNumericID() throws {
        let context = try PublishingContext.initialize(for: TestSite(), from: #filePath)
        let output = PublishingContext.withCurrent(context) {
            Analytics(.clicky(siteID: "1); alert(document.cookie); (0")).clickyCode(for: "1); alert(document.cookie); (0")
        }

        #expect(output == """
        <!-- Clicky Analytics -->
        <script>var clicky_site_ids = clicky_site_ids || []; \
        clicky_site_ids.push('1); alert(document.cookie); (0');</script>
        <script async src="//static.getclicky.com/js"></script>
        """)
        #expect(context.warnings.contains { $0.contains("Clicky") && $0.contains("number") })
    }

    @Test("A Clicky site ID cannot close its script element", .publishingContext())
    func clickyScriptClosingID() {
        let output = Analytics(.clicky(siteID: "</script>")).clickyCode(for: "</script>")
        #expect(output.contains(#"clicky_site_ids.push('\u003C/script\u003E');</script>"#))
    }

    @Test("A Fathom site ID cannot end its attribute", .publishingContext())
    func fathomHostileID() {
        let output = Analytics(.fathom(siteID: Self.hostile)).fathomCode(for: Self.hostile)
        #expect(output == """
        <!-- Fathom Analytics -->
        <script src="https://cdn.usefathom.com/script.js" data-site="\(Self.hostileAttribute)" defer></script>
        """)
    }

    @Test("A Plausible domain cannot end its attribute", .publishingContext())
    func plausibleHostileDomain() {
        let output = Analytics(.plausible(domain: Self.hostile)).plausibleCode(for: Self.hostile, using: [])
        #expect(output == """
        <!-- Plausible Analytics -->
        <script defer data-domain="\(Self.hostileAttribute)" src="https://plausible.io/js/script.js"></script>
        """)
    }

    @Test("A TelemetryDeck app ID cannot end its attribute", .publishingContext())
    func telemetryDeckHostileID() {
        let output = Analytics(.telemetryDeck(siteID: Self.hostile)).telemetryDeckCode(for: Self.hostile)
        #expect(output.contains("data-app-id=\"\(Self.hostileAttribute)\""))
    }

    @Test("A Google Analytics measurement ID cannot change the script's address", .publishingContext())
    func googleAnalyticsHostileID() {
        let output = Analytics(.googleAnalytics(measurementID: #"G-1&x=2"><b>"#))
            .googleAnalyticsCode(for: #"G-1&x=2"><b>"#)
        #expect(output.contains(#"<script async src="https://www.googletagmanager.com/gtag/js?id=G-1%26x%3D2%22%3E%3Cb%3E"></script>"#))
    }
}
