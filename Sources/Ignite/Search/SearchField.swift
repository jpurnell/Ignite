//
//  SearchField.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// Fields that can be included in the search index.
public enum SearchField: String, Sendable, CaseIterable {
    case title
    case description
    case tags
    case content
    case author

    /// The relative weight of this field in search ranking.
    var weight: Double {
        switch self {
        case .title: 3.0
        case .tags: 2.5
        case .description: 2.0
        case .author: 1.5
        case .content: 1.0
        }
    }
}
