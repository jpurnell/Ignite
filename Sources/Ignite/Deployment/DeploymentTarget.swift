//
//  DeploymentTarget.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// A hosting provider that Ignite can deploy to.
public protocol DeploymentTarget: Sendable {
    var name: String { get }

    func validate() throws

    func deploy(
        buildDirectory: URL,
        diff: DeploymentDiff?,
        dryRun: Bool
    ) async throws -> DeploymentResult
}
