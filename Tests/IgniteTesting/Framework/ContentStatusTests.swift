//
//  ContentStatusTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `ContentStatus` enum and Article draft/scheduling extensions.
@Suite("ContentStatus Tests")
struct ContentStatusTests {

    // MARK: - ContentStatus enum ordering

    @Test("ContentStatus has correct ordering: draft < scheduled < published < expired", .publishingContext())
    func statusOrdering() async throws {
        #expect(ContentStatus.draft < .scheduled)
        #expect(ContentStatus.scheduled < .published)
        #expect(ContentStatus.published < .expired)
        #expect(ContentStatus.draft < .expired)
    }

    @Test("ContentStatus equality works", .publishingContext())
    func statusEquality() async throws {
        #expect(ContentStatus.draft == .draft)
        #expect(ContentStatus.published == .published)
        #expect(ContentStatus.draft != .published)
    }

    @Test("ContentStatus raw values are correct strings", .publishingContext())
    func statusRawValues() async throws {
        #expect(ContentStatus.draft.rawValue == "draft")
        #expect(ContentStatus.scheduled.rawValue == "scheduled")
        #expect(ContentStatus.published.rawValue == "published")
        #expect(ContentStatus.expired.rawValue == "expired")
    }

    // MARK: - Article.isDraft

    @Test("isDraft defaults to false", .publishingContext())
    func isDraftDefault() async throws {
        let article = Article()
        #expect(article.isDraft == false)
    }

    @Test("isDraft recognizes 'true'", .publishingContext())
    func isDraftTrue() async throws {
        var article = Article()
        article.metadata["draft"] = "true"
        #expect(article.isDraft == true)
    }

    @Test("isDraft recognizes 'yes'", .publishingContext())
    func isDraftYes() async throws {
        var article = Article()
        article.metadata["draft"] = "yes"
        #expect(article.isDraft == true)
    }

    @Test("isDraft recognizes '1'", .publishingContext())
    func isDraftOne() async throws {
        var article = Article()
        article.metadata["draft"] = "1"
        #expect(article.isDraft == true)
    }

    @Test("isDraft is case-insensitive", .publishingContext())
    func isDraftCaseInsensitive() async throws {
        var article = Article()
        article.metadata["draft"] = "True"
        #expect(article.isDraft == true)

        article.metadata["draft"] = "YES"
        #expect(article.isDraft == true)
    }

    @Test("isDraft treats unrecognized values as false", .publishingContext())
    func isDraftUnrecognized() async throws {
        var article = Article()
        article.metadata["draft"] = "maybe"
        #expect(article.isDraft == false)
    }

    @Test("isDraft treats 'false' as not draft", .publishingContext())
    func isDraftFalse() async throws {
        var article = Article()
        article.metadata["draft"] = "false"
        #expect(article.isDraft == false)
    }

    // MARK: - Article.scheduledDate

    @Test("scheduledDate returns nil when not set", .publishingContext())
    func scheduledDateNil() async throws {
        let article = Article()
        #expect(article.scheduledDate == nil)
    }

    @Test("scheduledDate parses date-only format", .publishingContext())
    func scheduledDateOnly() async throws {
        var article = Article()
        article.metadata["scheduled"] = "2026-06-15"

        let scheduled = try #require(article.scheduledDate)
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: .gmt, from: scheduled)
        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 15)
    }

    @Test("scheduledDate parses date-time format", .publishingContext())
    func scheduledDateTime() async throws {
        var article = Article()
        article.metadata["scheduled"] = "2026-06-15 09:00"

        let scheduled = try #require(article.scheduledDate)
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: .gmt, from: scheduled)
        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 15)
        #expect(components.hour == 9)
        #expect(components.minute == 0)
    }

    @Test("scheduledDate returns nil for unparseable date", .publishingContext())
    func scheduledDateInvalid() async throws {
        var article = Article()
        article.metadata["scheduled"] = "not-a-date"
        #expect(article.scheduledDate == nil)
    }

    // MARK: - Article.expiresDate

    @Test("expiresDate returns nil when not set", .publishingContext())
    func expiresDateNil() async throws {
        let article = Article()
        #expect(article.expiresDate == nil)
    }

    @Test("expiresDate parses date-only format", .publishingContext())
    func expiresDateOnly() async throws {
        var article = Article()
        article.metadata["expires"] = "2026-09-01"

        let expires = try #require(article.expiresDate)
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: .gmt, from: expires)
        #expect(components.year == 2026)
        #expect(components.month == 9)
        #expect(components.day == 1)
    }

    @Test("expiresDate returns nil for unparseable date", .publishingContext())
    func expiresDateInvalid() async throws {
        var article = Article()
        article.metadata["expires"] = "never"
        #expect(article.expiresDate == nil)
    }

    // MARK: - Article.contentStatus(at:)

    @Test("Default article has published status", .publishingContext())
    func contentStatusDefault() async throws {
        let article = Article()
        #expect(article.contentStatus() == .published)
    }

    @Test("Draft article has draft status regardless of dates", .publishingContext())
    func contentStatusDraft() async throws {
        var article = Article()
        article.metadata["draft"] = "true"
        #expect(article.contentStatus() == .draft)
    }

    @Test("Article with future scheduled date has scheduled status", .publishingContext())
    func contentStatusScheduledFuture() async throws {
        var article = Article()
        article.metadata["scheduled"] = "2099-01-01"

        #expect(article.contentStatus() == .scheduled)
    }

    @Test("Article with past scheduled date has published status", .publishingContext())
    func contentStatusScheduledPast() async throws {
        var article = Article()
        article.metadata["scheduled"] = "2020-01-01"

        #expect(article.contentStatus() == .published)
    }

    @Test("Article with past expiration date has expired status", .publishingContext())
    func contentStatusExpired() async throws {
        var article = Article()
        article.metadata["expires"] = "2020-01-01"

        #expect(article.contentStatus() == .expired)
    }

    @Test("Article with future expiration date has published status", .publishingContext())
    func contentStatusNotYetExpired() async throws {
        var article = Article()
        article.metadata["expires"] = "2099-01-01"

        #expect(article.contentStatus() == .published)
    }

    @Test("Draft takes priority over scheduled", .publishingContext())
    func contentStatusDraftOverridesScheduled() async throws {
        var article = Article()
        article.metadata["draft"] = "true"
        article.metadata["scheduled"] = "2099-01-01"

        #expect(article.contentStatus() == .draft)
    }

    @Test("Draft takes priority over expired", .publishingContext())
    func contentStatusDraftOverridesExpired() async throws {
        var article = Article()
        article.metadata["draft"] = "true"
        article.metadata["expires"] = "2020-01-01"

        #expect(article.contentStatus() == .draft)
    }

    @Test("Scheduled takes priority over expired when both future", .publishingContext())
    func contentStatusScheduledBeforeExpires() async throws {
        var article = Article()
        article.metadata["scheduled"] = "2099-06-01"
        article.metadata["expires"] = "2099-12-01"

        #expect(article.contentStatus() == .scheduled)
    }

    @Test("contentStatus respects effectiveDate parameter", .publishingContext())
    func contentStatusWithEffectiveDate() async throws {
        var article = Article()
        article.metadata["scheduled"] = "2026-06-15"

        let formatter = DateFormatter()
        formatter.dateFormat = "y-M-d"
        formatter.timeZone = .gmt

        let beforeScheduled = try #require(formatter.date(from: "2026-06-14"))
        let afterScheduled = try #require(formatter.date(from: "2026-06-16"))

        #expect(article.contentStatus(at: beforeScheduled) == .scheduled)
        #expect(article.contentStatus(at: afterScheduled) == .published)
    }

    @Test("contentStatus date simulation works for expiration", .publishingContext())
    func contentStatusExpirationWithEffectiveDate() async throws {
        var article = Article()
        article.metadata["expires"] = "2026-09-01"

        let formatter = DateFormatter()
        formatter.dateFormat = "y-M-d"
        formatter.timeZone = .gmt

        let beforeExpires = try #require(formatter.date(from: "2026-08-31"))
        let onExpires = try #require(formatter.date(from: "2026-09-01"))

        #expect(article.contentStatus(at: beforeExpires) == .published)
        #expect(article.contentStatus(at: onExpires) == .expired)
    }

    // MARK: - Backward compatibility

    @Test("isPublished false still works independently of isDraft", .publishingContext())
    func isPublishedAndIsDraftAreIndependent() async throws {
        var article = Article()
        article.metadata["published"] = "false"

        #expect(article.isPublished == false)
        #expect(article.isDraft == false)
        #expect(article.contentStatus() == .published)
    }
}
