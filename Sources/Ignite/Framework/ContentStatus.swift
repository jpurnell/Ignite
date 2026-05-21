//
//  ContentStatus.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// The publication status of a piece of content.
public enum ContentStatus: String, Sendable, Comparable {
    /// Content is a work-in-progress, excluded from production builds.
    case draft

    /// Content is scheduled for a future date, excluded until that date.
    case scheduled

    /// Content is published and visible in all builds.
    case published

    /// Content has passed its expiration date.
    case expired

    public static func < (lhs: ContentStatus, rhs: ContentStatus) -> Bool {
        let order: [ContentStatus] = [.draft, .scheduled, .published, .expired]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else { return false }
        return lhsIndex < rhsIndex
    }
}
