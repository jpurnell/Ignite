//
//  DraftBannerTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `DraftBanner` element.
@Suite("DraftBanner Tests")
class DraftBannerTests: IgniteTestSuite {

    @Test("Draft status renders red banner", .publishingContext())
    func draftBanner() async throws {
        let output = DraftBanner(status: .draft).markupString()

        #expect(output.contains("DRAFT"))
        #expect(output.contains("#dc3545"))
    }

    @Test("Scheduled status renders orange banner", .publishingContext())
    func scheduledBanner() async throws {
        let output = DraftBanner(status: .scheduled).markupString()

        #expect(output.contains("SCHEDULED"))
        #expect(output.contains("#fd7e14"))
    }

    @Test("Expired status renders gray banner", .publishingContext())
    func expiredBanner() async throws {
        let output = DraftBanner(status: .expired).markupString()

        #expect(output.contains("EXPIRED"))
        #expect(output.contains("#6c757d"))
    }

    @Test("Published status renders nothing", .publishingContext())
    func publishedBannerEmpty() async throws {
        let output = DraftBanner(status: .published).markupString()

        #expect(!output.contains("DRAFT"))
        #expect(!output.contains("SCHEDULED"))
        #expect(!output.contains("EXPIRED"))
    }

    @Test("Banner includes production warning text", .publishingContext())
    func bannerWarningText() async throws {
        let output = DraftBanner(status: .draft).markupString()

        #expect(output.contains("will not appear in production builds"))
    }

    @Test("Banner uses fixed positioning", .publishingContext())
    func bannerPositioning() async throws {
        let output = DraftBanner(status: .draft).markupString()

        #expect(output.contains("position:fixed"))
        #expect(output.contains("z-index:9999"))
    }
}
