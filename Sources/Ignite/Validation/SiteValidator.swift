//
//  SiteValidator.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// A rule that validates some aspect of a site's content at build time.
public protocol SiteValidator: Sendable {
    var name: String { get }
    func validate(articles: [Article]) -> [ValidationRule]
}
