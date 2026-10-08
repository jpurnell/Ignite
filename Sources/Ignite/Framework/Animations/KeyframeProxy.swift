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
    /// - Returns: A keyframe with no styles, ready to have them added. A position outside
    /// `0%` through `100%` is moved to the nearer end, and a warning is added to the build.
    public func callAsFunction(_ position: Percentage) -> Keyframe {
        Keyframe(position)
    }
}
