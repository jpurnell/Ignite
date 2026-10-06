//
// MotionQuery.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Applies styles based on the user's motion preferences.
public enum MotionQuery: String, Query, CaseIterable {
    /// Reduced motion preference
    case reduced = "prefers-reduced-motion: reduce"
    /// Standard motion preference
    case allowed = "prefers-reduced-motion: no-preference"

    /// The raw CSS media feature string.
    public var condition: String { rawValue }
}

extension MotionQuery: MediaFeature {
    /// The media feature as it is written in CSS.
    public var description: String {
        rawValue
    }
}
