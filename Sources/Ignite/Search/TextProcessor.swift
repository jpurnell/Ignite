//
//  TextProcessor.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// Text processing utilities for search indexing.
public enum TextProcessor {
    /// Removes all HTML tags and entities, collapsing whitespace.
    public static func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&[^;]+;", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generates a plain-text excerpt of the specified length, breaking at a word boundary.
    public static func excerpt(from text: String, length: Int) -> String {
        guard text.count > length else { return text }
        let truncated = String(text.prefix(length))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[truncated.startIndex..<lastSpace]) + "..."
        }
        return truncated + "..."
    }

    /// Tokenizes text into individual searchable terms.
    public static func tokenize(
        _ text: String,
        language: SearchLanguage,
        stem: Bool,
        removeStopWords: Bool
    ) -> [String] {
        let words = text
            .lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty }

        var tokens = words

        if removeStopWords {
            let stopWords = language.stopWords
            tokens = tokens.filter { !stopWords.contains($0) }
        }

        if stem {
            tokens = tokens.map { stemWord($0, language: language) }
        }

        var seen = Set<String>()
        tokens = tokens.filter { seen.insert($0).inserted }

        return tokens
    }

    /// Applies basic Porter stemming rules for English.
    public static func stemWord(_ word: String, language: SearchLanguage) -> String {
        guard language == .english else { return word }
        guard word.count > 3 else { return word }

        var stem = word

        let suffixes: [(String, String)] = [
            ("ousness", "ous"), ("iveness", "ive"), ("fulness", "ful"),
            ("ization", "ize"), ("ational", "ate"),
            ("tional", "tion"), ("biliti", "ble"), ("iviti", "ive"),
            ("aliti", "al"), ("ousli", "ous"), ("entli", "ent"),
            ("alism", "al"), ("ation", "ate"), ("ator", "ate"),
            ("anci", "ance"), ("enci", "ence"), ("izer", "ize"),
            ("alli", "al"), ("eli", "e")
        ]

        for (suffix, replacement) in suffixes {
            if stem.hasSuffix(suffix) {
                return String(stem.dropLast(suffix.count)) + replacement
            }
        }

        let simpleSuffixes = ["ing", "tion", "ness", "ment", "able", "ible",
                              "ful", "less", "ous", "ive", "ly", "ed", "er", "es", "s"]
        for suffix in simpleSuffixes {
            if stem.hasSuffix(suffix) && stem.count - suffix.count >= 3 {
                stem = String(stem.dropLast(suffix.count))
                break
            }
        }

        return stem
    }
}
