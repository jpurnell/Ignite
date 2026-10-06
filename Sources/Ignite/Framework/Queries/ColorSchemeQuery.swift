//
// ColorSchemeQuery.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Applies styles based on the user's preferred color scheme.
public enum ColorSchemeQuery: String, Query, CaseIterable {
    /// Dark mode preference
    case dark = "prefers-color-scheme: dark"
    /// Light mode preference
    case light = "prefers-color-scheme: light"

    /// The raw CSS media feature string.
    public var condition: String { rawValue }
}

extension ColorSchemeQuery: MediaFeature {
    /// The media feature as it is written in CSS.
    public var description: String {
        rawValue
    }
}
