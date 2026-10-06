//
// Axis.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Describes the axes of a coordinate system.
public struct Axis: OptionSet, Sendable {
    /// The bit mask that stores which axes are selected.
    public let rawValue: Int

    /// Creates a set of axes from a bit mask.
    /// - Parameter rawValue: The bit mask, with one bit for each axis.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The horizontal axis.
    public static let horizontal = Axis(rawValue: 1 << 0)

    /// The vertical axis.
    public static let vertical = Axis(rawValue: 1 << 1)
}

public extension Axis {
    /// A set containing both horizontal and vertical axes.
    static let all: Axis = [.horizontal, .vertical]
}
