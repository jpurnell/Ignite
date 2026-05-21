//
//  SearchConfiguration.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// Configuration for Ignite's built-in search.
public struct SearchConfiguration: Sendable {
    /// Whether search index generation is enabled.
    public var enabled: Bool

    /// Which content types to include in the search index.
    /// Nil means index all published content.
    public var contentTypes: [String]?

    /// Maximum length of content excerpts stored in the index (in characters).
    public var excerptLength: Int

    /// Fields to include in the search index.
    public var indexedFields: Set<SearchField>

    /// Whether to apply stemming to indexed content.
    public var enableStemming: Bool

    /// Whether to remove common stop words from the index.
    public var removeStopWords: Bool

    /// The language for stemming and stop-word lists.
    public var language: SearchLanguage

    /// Output path for the search index JSON file.
    public var indexPath: String

    /// Output path for the search JavaScript file.
    public var scriptPath: String

    /// Default configuration with sensible values.
    public static let `default` = SearchConfiguration(
        enabled: true,
        contentTypes: nil,
        excerptLength: 300,
        indexedFields: [.title, .description, .tags, .content, .author],
        enableStemming: true,
        removeStopWords: true,
        language: .english,
        indexPath: "/search-index.json",
        scriptPath: "/js/ignite-search.js"
    )

    /// Disabled configuration.
    public static let disabled = SearchConfiguration(
        enabled: false,
        contentTypes: nil,
        excerptLength: 0,
        indexedFields: [],
        enableStemming: false,
        removeStopWords: false,
        language: .english,
        indexPath: "",
        scriptPath: ""
    )
}
