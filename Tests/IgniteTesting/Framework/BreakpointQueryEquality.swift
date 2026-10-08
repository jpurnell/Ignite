//
//  BreakpointQueryEquality.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A light theme whose ID is `paper-light`.
private struct PaperTheme: Theme {
    var colorScheme: ColorScheme = .light
}

/// A light theme whose ID, `paper-lightweight-light`, begins with `PaperTheme`'s.
private struct PaperLightweightTheme: Theme {
    var colorScheme: ColorScheme = .light
}

/// Tests that `BreakpointQuery`'s `==` and `hash(into:)` describe one equivalence, so the
/// type behaves in a `Set` and as a `Dictionary` key.
@Suite("BreakpointQuery equality Tests")
struct BreakpointQueryEqualityTests {
    private func hash(of query: BreakpointQuery) -> Int {
        var hasher = Hasher()
        query.hash(into: &hasher)
        return hasher.finalize()
    }

    @Test("The two test themes have IDs where one is a prefix of the other")
    func themeIDsOverlap() {
        #expect(PaperTheme().cssID == "paper-light")
        #expect(PaperLightweightTheme().cssID == "paper-lightweight-light")
    }

    @Test("Queries for themes whose IDs share a prefix are different queries, in both directions")
    func prefixIsNotEquality() {
        let paper = BreakpointQuery.medium.withTheme(PaperTheme())
        let lightweight = BreakpointQuery.medium.withTheme(PaperLightweightTheme())

        #expect((lightweight == paper) == false)
        #expect((paper == lightweight) == false)
    }

    @Test("Equality is symmetric", arguments: [0, 1, 2, 3], [0, 1, 2, 3])
    func equalityIsSymmetric(left: Int, right: Int) {
        let queries: [BreakpointQuery] = [
            .medium,
            .medium.withTheme(PaperTheme()),
            .medium.withTheme(PaperLightweightTheme()),
            .large.withTheme(PaperTheme())
        ]

        #expect((queries[left] == queries[right]) == (queries[right] == queries[left]))
        #expect((queries[left] == queries[right]) == (left == right))
    }

    @Test("Equal queries hash alike")
    func equalQueriesHashAlike() {
        let first = BreakpointQuery.medium.withTheme(PaperTheme())
        let second = BreakpointQuery.medium.withTheme(PaperTheme())

        #expect(first == second)
        #expect(hash(of: first) == hash(of: second))
        #expect(BreakpointQuery.small == BreakpointQuery.small)
        #expect(hash(of: .small) == hash(of: .small))
        #expect(hash(of: .custom(.px(800))) == hash(of: .custom(.px(800))))
    }

    @Test("A set keeps one query per breakpoint and theme")
    func setMembership() {
        let queries: Set<BreakpointQuery> = [
            .medium,
            .medium,
            .medium.withTheme(PaperTheme()),
            .medium.withTheme(PaperTheme()),
            .medium.withTheme(PaperLightweightTheme()),
            .large.withTheme(PaperTheme())
        ]

        #expect(queries.count == 4)
        #expect(queries.contains(.medium.withTheme(PaperLightweightTheme())))
        #expect(queries.contains(.small.withTheme(PaperTheme())) == false)
    }

    @Test("A query with a theme is not the query without one")
    func themedAndUnthemedDiffer() {
        #expect(BreakpointQuery.medium != BreakpointQuery.medium.withTheme(PaperTheme()))
        #expect(BreakpointQuery.medium.withTheme(PaperTheme()) != BreakpointQuery.medium)
    }
}
