//
// Keyframe.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A proxy type that enables a function-like syntax for creating keyframes.
public struct KeyframeProxy {
    /// Creates a keyframe at the given position in the animation timeline.
    /// - Parameter position: Where the keyframe sits, from `0%` through `100%`.
    /// - Returns: A keyframe with no styles, ready to have them added.
    /// - Precondition: `position` must be between `0%` and `100%`. A position outside
    /// that range stops the program.
    public func callAsFunction(_ position: Percentage) -> Keyframe {
        Keyframe(position)
    }
}
