//
//  DeploymentDiff.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// Tracks which files changed between builds to enable incremental deployment.
public struct DeploymentDiff: Sendable {
    public let added: Set<String>
    public let removed: Set<String>
    public let unchanged: Set<String>
    public let isAvailable: Bool

    public init(added: Set<String>, removed: Set<String>, unchanged: Set<String>) {
        self.added = added
        self.removed = removed
        self.unchanged = unchanged
        self.isAvailable = true
    }

    private init(added: Set<String>, removed: Set<String>, unchanged: Set<String>, isAvailable: Bool) {
        self.added = added
        self.removed = removed
        self.unchanged = unchanged
        self.isAvailable = isAvailable
    }

    public var hasChanges: Bool {
        !added.isEmpty || !removed.isEmpty
    }

    public var totalFileCount: Int {
        added.count + removed.count + unchanged.count
    }

    /// Creates a diff representing a first-time deployment where every file is new.
    public static func firstDeploy(fileCount: Int) -> DeploymentDiff {
        DeploymentDiff(
            added: Set((0..<fileCount).map { "file-\($0)" }),
            removed: [],
            unchanged: [],
            isAvailable: false
        )
    }
}

/// A record of what was deployed last time.
public struct DeploymentManifest: Codable, Sendable {
    public let files: [String: String]
    public let timestamp: Date
    public let targetName: String

    public init(files: [String: String], timestamp: Date, targetName: String) {
        self.files = files
        self.timestamp = timestamp
        self.targetName = targetName
    }
}
