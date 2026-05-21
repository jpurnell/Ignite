//
//  DeploymentTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the deployment foundation types.
@Suite("Deployment Tests")
struct DeploymentTests {

    // MARK: - DeploymentDiff

    @Test("Diff reports added files")
    func diffAdded() {
        let diff = DeploymentDiff(
            added: ["index.html", "about.html"],
            removed: [],
            unchanged: ["style.css"]
        )
        #expect(diff.added.count == 2)
        #expect(diff.isAvailable)
    }

    @Test("Diff reports removed files")
    func diffRemoved() {
        let diff = DeploymentDiff(
            added: [],
            removed: ["old-page.html"],
            unchanged: ["index.html"]
        )
        #expect(diff.removed.count == 1)
    }

    @Test("Empty diff means no changes")
    func diffEmpty() {
        let diff = DeploymentDiff(
            added: [],
            removed: [],
            unchanged: ["index.html"]
        )
        #expect(!diff.hasChanges)
    }

    @Test("Diff with changes reports hasChanges")
    func diffHasChanges() {
        let diff = DeploymentDiff(
            added: ["new.html"],
            removed: [],
            unchanged: []
        )
        #expect(diff.hasChanges)
    }

    @Test("Total file count is correct")
    func diffTotalCount() {
        let diff = DeploymentDiff(
            added: ["a.html"],
            removed: ["b.html"],
            unchanged: ["c.html", "d.html"]
        )
        #expect(diff.totalFileCount == 4)
    }

    @Test("First deploy diff is not available")
    func firstDeployDiff() {
        let diff = DeploymentDiff.firstDeploy(fileCount: 5)
        #expect(!diff.isAvailable)
        #expect(diff.added.count == 5)
    }

    // MARK: - DeploymentResult

    @Test("Result summary includes file counts")
    func resultSummary() {
        let result = DeploymentResult(
            siteURL: URL(string: "https://example.com"),
            filesUploaded: 10,
            filesDeleted: 2,
            filesSkipped: 5,
            bytesTransferred: 1024,
            duration: .seconds(3),
            isDryRun: false,
            warnings: []
        )
        #expect(result.summary.contains("10"))
        #expect(result.summary.contains("example.com"))
    }

    @Test("Dry run summary says 'Would deploy'")
    func dryRunSummary() {
        let result = DeploymentResult(
            siteURL: nil,
            filesUploaded: 5,
            filesDeleted: 0,
            filesSkipped: 0,
            bytesTransferred: 0,
            duration: .seconds(1),
            isDryRun: true,
            warnings: []
        )
        #expect(result.summary.contains("Would deploy"))
    }

    @Test("Real deploy summary says 'Deployed'")
    func realDeploySummary() {
        let result = DeploymentResult(
            siteURL: nil,
            filesUploaded: 3,
            filesDeleted: 0,
            filesSkipped: 0,
            bytesTransferred: 0,
            duration: .seconds(1),
            isDryRun: false,
            warnings: []
        )
        #expect(result.summary.contains("Deployed"))
    }

    // MARK: - DeploymentManifest

    @Test("Manifest is Codable round-trip")
    func manifestCodable() throws {
        let manifest = DeploymentManifest(
            files: ["index.html": "abc123", "style.css": "def456"],
            timestamp: Date(timeIntervalSince1970: 1000000),
            targetName: "GitHub Pages"
        )
        let data = try JSONEncoder().encode(manifest)
        let decoded = try JSONDecoder().decode(DeploymentManifest.self, from: data)

        #expect(decoded.files.count == 2)
        #expect(decoded.files["index.html"] == "abc123")
        #expect(decoded.targetName == "GitHub Pages")
    }

    // MARK: - DeploymentEnvironment

    @Test("Optional returns nil for missing variable")
    func envOptionalMissing() {
        #expect(DeploymentEnvironment.optional("IGNITE_TEST_NONEXISTENT_VAR_12345") == nil)
    }

    @Test("Required throws for missing variable")
    func envRequiredThrows() {
        #expect(throws: DeploymentError.self) {
            try DeploymentEnvironment.required("IGNITE_TEST_NONEXISTENT_VAR_12345")
        }
    }

    // MARK: - DeploymentError

    @Test("Error descriptions are human-readable")
    func errorDescriptions() {
        let errors: [DeploymentError] = [
            .missingEnvironmentVariable("TOKEN"),
            .missingConfiguration("repo URL"),
            .invalidBuildDirectory(URL(fileURLWithPath: "/tmp/build")),
            .targetRejected(statusCode: 403, message: "Forbidden"),
            .fileError("permission denied"),
            .networkError("timeout")
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}
