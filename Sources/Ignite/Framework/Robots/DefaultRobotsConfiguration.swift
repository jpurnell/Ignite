//
// DefaultRobotsConfiguration.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A simple default robots configuration that disallows nothing.
public struct DefaultRobotsConfiguration: RobotsConfiguration {
    /// Creates a robots configuration that disallows nothing.
    public init() { }
    /// The rules that keep robots away from parts of the site. This is empty by default.
    public var disallowRules = [DisallowRule]()
}
