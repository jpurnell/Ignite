//
//  SearchIndexGenerator.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// Generates a search index JSON file from a collection of articles.
public struct SearchIndexGenerator: Sendable {
    public let configuration: SearchConfiguration
    public let articles: [Article]

    public init(configuration: SearchConfiguration, articles: [Article]) {
        self.configuration = configuration
        self.articles = articles
    }

    /// Generates the search index as a JSON string.
    public func generateIndex() throws -> String {
        guard configuration.enabled else { return "" }

        let entries = articles
            .filter { $0.isPublished }
            .filter { article in
                guard let types = configuration.contentTypes else { return true }
                guard let articleType = article.metadata["type"] as? String else { return false }
                return types.contains(articleType)
            }
            .map { buildEntry(for: $0) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(entries)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private func buildEntry(for article: Article) -> SearchEntry {
        let plainText = TextProcessor.stripHTML(article.text)
        let excerpt = TextProcessor.excerpt(from: plainText, length: configuration.excerptLength)
        let tokens = tokenize(article: article)

        return SearchEntry(
            title: article.title,
            description: article.description,
            url: "/\(article.path)",
            tags: article.tags ?? [],
            author: article.author ?? "",
            excerpt: excerpt,
            date: ISO8601DateFormatter().string(from: article.date),
            tokens: tokens
        )
    }

    private func tokenize(article: Article) -> [String] {
        var allText = ""

        if configuration.indexedFields.contains(.title) {
            allText += " " + article.title
        }
        if configuration.indexedFields.contains(.description) {
            allText += " " + article.description
        }
        if configuration.indexedFields.contains(.tags) {
            allText += " " + (article.tags ?? []).joined(separator: " ")
        }
        if configuration.indexedFields.contains(.content) {
            allText += " " + TextProcessor.stripHTML(article.text)
        }
        if configuration.indexedFields.contains(.author) {
            allText += " " + (article.author ?? "")
        }

        return TextProcessor.tokenize(
            allText,
            language: configuration.language,
            stem: configuration.enableStemming,
            removeStopWords: configuration.removeStopWords
        )
    }
}
