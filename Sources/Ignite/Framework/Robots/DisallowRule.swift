//
// DisallowRule.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A rule that disallows one specific robot from one or more paths on your site.
public struct DisallowRule: Sendable {
    var name: String
    var paths: [String]

    /// Creates a rule that keeps one robot away from specific paths.
    /// - Parameters:
    ///   - name: The user-agent name of the robot, as it is written in robots.txt.
    ///   - paths: The paths the robot must not visit. Each one is written as its own `Disallow:` line.
    public init(name: String, paths: [String]) {
        self.name = name
        self.paths = paths
    }

    /// Creates a rule that keeps one robot away from the whole site, written as `Disallow: *`.
    /// - Parameter name: The user-agent name of the robot, as it is written in robots.txt.
    public init(name: String) {
        self.name = name
        self.paths = ["*"]
    }

    /// Creates a rule that keeps one well-known robot away from specific paths.
    /// - Parameters:
    ///   - robot: The robot to restrict.
    ///   - paths: The paths the robot must not visit. Each one is written as its own `Disallow:` line.
    public init(robot: KnownRobot, paths: [String]) {
        self.name = robot.rawValue
        self.paths = paths
    }

    /// Creates a rule that keeps one well-known robot away from the whole site, written as `Disallow: *`.
    /// - Parameter robot: The robot to restrict.
    public init(robot: KnownRobot) {
        self.name = robot.rawValue
        self.paths = ["*"]
    }
}
