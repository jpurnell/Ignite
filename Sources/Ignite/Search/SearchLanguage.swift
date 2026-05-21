//
//  SearchLanguage.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// Languages supported for stemming and stop-word removal.
public enum SearchLanguage: String, Sendable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"

    /// Stop words for this language.
    var stopWords: Set<String> {
        switch self {
        case .english:
            return ["a", "an", "the", "is", "are", "was", "were", "be", "been",
                    "being", "have", "has", "had", "do", "does", "did", "will",
                    "would", "could", "should", "may", "might", "shall", "can",
                    "to", "of", "in", "for", "on", "with", "at", "by", "from",
                    "as", "into", "through", "during", "before", "after", "and",
                    "but", "or", "nor", "not", "so", "yet", "both", "either",
                    "neither", "each", "every", "all", "any", "few", "more",
                    "most", "other", "some", "such", "no", "only", "own",
                    "same", "than", "too", "very", "just", "about", "above",
                    "below", "between", "up", "down", "out", "off", "over",
                    "under", "again", "further", "then", "once", "it", "its",
                    "this", "that", "these", "those", "i", "me", "my", "we",
                    "our", "you", "your", "he", "him", "his", "she", "her",
                    "they", "them", "their", "what", "which", "who", "whom",
                    "how", "when", "where", "why"]
        default:
            return []
        }
    }
}
