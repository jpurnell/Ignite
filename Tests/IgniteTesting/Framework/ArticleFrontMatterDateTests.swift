//
//  ArticleFrontMatterDateTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the dates an article reads from its front matter.
///
/// The parser fixes its own locale, calendar and time zone, so these instants hold on a
/// machine set to any region – including ones whose calendar is not Gregorian.
@Suite("Article front matter date Tests")
struct ArticleFrontMatterDateTests {
    @Test("Front matter dates are read as Gregorian dates in GMT", arguments: zip(
        ["2024-03-05", "2024-3-5", "2024-03-05 14:30", "2024-3-5 4:5", "2024-03-05 14:30:15", "1999-12-31 23:59:59"],
        [1_709_596_800, 1_709_596_800, 1_709_649_000, 1_709_611_500, 1_709_649_015, 946_684_799]))
    func parsesDate(string: String, secondsSince1970: Int) throws {
        let date = try #require(Article.frontMatterDate(from: string))

        #expect(Int(date.timeIntervalSince1970) == secondsSince1970)
    }

    @Test("Text that is not a date in a supported format is not parsed", arguments: [
        "", "yesterday", "05/03/2024", "2024-03-05T14:30:00Z"
    ])
    func rejectsOtherText(string: String) {
        #expect(Article.frontMatterDate(from: string) == nil)
    }
}
