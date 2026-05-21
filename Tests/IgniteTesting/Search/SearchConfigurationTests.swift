//
//  SearchConfigurationTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `SearchConfiguration`, `SearchField`, and `SearchLanguage` types.
@Suite("SearchConfiguration Tests")
struct SearchConfigurationTests {

    // MARK: - SearchField

    @Test("SearchField weights are ordered by relevance")
    func fieldWeights() {
        #expect(SearchField.title.weight > SearchField.content.weight)
        #expect(SearchField.tags.weight > SearchField.content.weight)
        #expect(SearchField.description.weight > SearchField.content.weight)
    }

    @Test("All SearchField cases are accounted for")
    func allFieldCases() {
        let all = SearchField.allCases
        #expect(all.contains(.title))
        #expect(all.contains(.description))
        #expect(all.contains(.tags))
        #expect(all.contains(.content))
        #expect(all.contains(.author))
        #expect(all.count == 5)
    }

    // MARK: - SearchLanguage

    @Test("English stop words include common words")
    func englishStopWords() {
        let stops = SearchLanguage.english.stopWords
        #expect(stops.contains("the"))
        #expect(stops.contains("a"))
        #expect(stops.contains("is"))
        #expect(stops.contains("and"))
    }

    @Test("Non-English languages return empty stop words")
    func nonEnglishStopWords() {
        #expect(SearchLanguage.spanish.stopWords.isEmpty)
        #expect(SearchLanguage.french.stopWords.isEmpty)
        #expect(SearchLanguage.german.stopWords.isEmpty)
    }

    // MARK: - SearchConfiguration

    @Test("Default configuration has sensible values")
    func defaultConfig() {
        let config = SearchConfiguration.default
        #expect(config.enabled)
        #expect(config.contentTypes == nil)
        #expect(config.excerptLength == 300)
        #expect(config.enableStemming)
        #expect(config.removeStopWords)
        #expect(config.language == .english)
        #expect(config.indexedFields.contains(.title))
        #expect(config.indexedFields.contains(.content))
    }

    @Test("Disabled configuration has enabled false")
    func disabledConfig() {
        let config = SearchConfiguration.disabled
        #expect(!config.enabled)
        #expect(config.indexedFields.isEmpty)
    }
}
