//
//  SearchEntry.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// A single entry in the search index, representing one piece of content.
public struct SearchEntry: Codable, Sendable {
    public let title: String
    public let description: String
    public let url: String
    public let tags: [String]
    public let author: String
    public let excerpt: String
    public let date: String
    public let tokens: [String]
}
