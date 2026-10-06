//
// CSSBuilder.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

typealias RulesetBuilder = CSSBuilder<Ruleset>
typealias StyleBuilder = CSSBuilder<InlineStyle>

/// A generic result builder for creating arrays of CSS elements (Ruleset or InlineStyle)
@resultBuilder
struct CSSBuilder<Element> {
    static func buildBlock(_ components: [Element]) -> [Element] {
        components
    }

    static func buildExpression(_ expression: [Element]) -> [Element] {
        expression
    }

    static func buildExpression(_ expression: Element) -> [Element] {
        [expression]
    }
}
