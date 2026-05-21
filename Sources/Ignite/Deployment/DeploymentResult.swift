//
//  DeploymentResult.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// The outcome of a deployment operation.
public struct DeploymentResult: Sendable {
    public let siteURL: URL?
    public let filesUploaded: Int
    public let filesDeleted: Int
    public let filesSkipped: Int
    public let bytesTransferred: Int64
    public let duration: Duration
    public let isDryRun: Bool
    public let warnings: [String]

    public var summary: String {
        let action = isDryRun ? "Would deploy" : "Deployed"
        var parts = ["\(action) \(filesUploaded) files"]
        if filesDeleted > 0 { parts.append("deleted \(filesDeleted)") }
        if filesSkipped > 0 { parts.append("skipped \(filesSkipped) unchanged") }
        if let url = siteURL { parts.append("to \(url.absoluteString)") }
        return parts.joined(separator: ", ")
    }
}
