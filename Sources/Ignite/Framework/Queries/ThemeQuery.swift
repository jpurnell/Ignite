//
// ThemeQuery.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Applies styles based on the current theme.
public struct ThemeQuery: Query {
    /// The theme identifier
    let theme: any Theme.Type

    /// Creates a query that matches while the given theme is active.
    /// - Parameter theme: The type of the theme to match.
    public init(_ theme: any Theme.Type) {
        self.theme = theme
    }

    /// The attribute condition that matches the theme: a `data-bs-theme` value that begins with the theme's ID prefix.
    public var condition: String {
        "data-bs-theme^=\"\(theme.idPrefix)\""
    }

    /// Hashes the ID prefix of the theme.
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(theme.idPrefix)
    }

    /// Two theme queries are equal when their themes have the same ID prefix.
    nonisolated public static func == (lhs: ThemeQuery, rhs: ThemeQuery) -> Bool {
        lhs.theme.idPrefix == rhs.theme.idPrefix
    }
}
