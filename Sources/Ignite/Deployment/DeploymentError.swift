//
//  DeploymentError.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// Errors that can occur during deployment.
public enum DeploymentError: LocalizedError, Sendable {
    case missingEnvironmentVariable(String)
    case missingConfiguration(String)
    case invalidBuildDirectory(URL)
    case targetRejected(statusCode: Int, message: String)
    case fileError(String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let key):
            "Missing environment variable: \(key). Set it before deploying."
        case .missingConfiguration(let detail):
            "Deployment configuration incomplete: \(detail)"
        case .invalidBuildDirectory(let url):
            "Build directory not found or empty: \(url.path)"
        case .targetRejected(let code, let message):
            "Deployment rejected (\(code)): \(message)"
        case .fileError(let detail):
            "File error during deployment: \(detail)"
        case .networkError(let detail):
            "Network error during deployment: \(detail)"
        }
    }
}
