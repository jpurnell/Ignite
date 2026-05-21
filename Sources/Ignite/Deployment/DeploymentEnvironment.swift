//
//  DeploymentEnvironment.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// Reads deployment secrets from environment variables.
public struct DeploymentEnvironment: Sendable {
    /// Reads a required environment variable, throwing if not set.
    public static func required(_ key: String) throws -> String {
        guard let value = ProcessInfo.processInfo.environment[key] else {
            throw DeploymentError.missingEnvironmentVariable(key)
        }
        return value
    }

    /// Reads an optional environment variable.
    public static func optional(_ key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }
}
