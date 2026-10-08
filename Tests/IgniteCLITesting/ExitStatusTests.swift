//
// ExitStatusTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import IgniteCLI

/// Tests of the tool as a script sees it: the built `IgniteCLI` program is run, and its
/// exit status and its two outputs are read.
///
/// These are the failures that need no compiler and no network to reach. Each run is
/// the tool itself in an empty directory, and ends in a fraction of a second. The suite
/// runs one test at a time for the reason given on `ProcessExecuteTests`.
@Suite("Exit Status Tests", .serialized)
struct ExitStatusTests {
    /// The tool, built into the same directory as the tests.
    private func tool() throws -> String {
        // The bundle these tests were built into sits beside the products of the same build.
        let bundle = Bundle(for: CapturedOutput.self)
        let tool = bundle.bundleURL.deletingLastPathComponent().appending(path: "IgniteCLI").path
        try #require(FileManager.default.isExecutableFile(atPath: tool), "No built tool at \(tool).")
        return tool
    }

    /// Runs the tool in a new, empty directory.
    /// - Parameters:
    ///   - arguments: The arguments to give it.
    ///   - prepare: Called with the directory before the tool runs.
    private func run(_ arguments: [String], prepare: (URL) throws -> Void = { _ in }) throws -> CommandResult {
        let directory = FileManager.default.temporaryDirectory.appending(path: "ignite-exit-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                Issue.record("Could not remove \(directory.path): \(error)")
            }
        }

        try prepare(directory)
        return try Process.execute(command: [try tool()] + arguments, timeout: 60, in: directory)
    }

    @Test("ignite build with no package exits with 1 and its message on standard error")
    func buildWithoutPackage() throws {
        let result = try run(["build"])
        #expect(result.status == 1)
        #expect(result.error == "❌ Can't find Package.swift in the current directory.\n")
        #expect(result.output == "")
    }

    @Test("ignite new with a template that is not https exits with 1 and its message on standard error")
    func newWithInsecureTemplate() throws {
        let result = try run(["new", "MySite", "--template", "git@example.com:me/site.git"])
        #expect(result.status == 1)
        #expect(result.error == "❌ Template URL must start with https://\n")
        #expect(result.output == "")
    }

    @Test("ignite new over an existing folder exits with 1 and leaves the folder alone")
    func newOverExistingDirectory() throws {
        var kept = ""
        let result = try run(["new", "MySite"]) { directory in
            let site = directory.appending(path: "MySite")
            try FileManager.default.createDirectory(at: site, withIntermediateDirectories: true)
            try "mine".write(to: site.appending(path: "keep.txt"), atomically: true, encoding: .utf8)
            kept = site.appending(path: "keep.txt").path
        }
        #expect(result.status == 1)
        #expect(result.error == "❌ Directory 'MySite' is not empty; aborting.\n")
        #expect(result.output == "")
        // The directory is removed with the fixture; what matters is the tool's report.
        #expect(kept.hasSuffix("MySite/keep.txt"))
    }

    @Test("ignite run with nothing to serve exits with 1 and its message on standard error")
    func runWithoutBuildDirectory() throws {
        let result = try run(["run"])
        #expect(result.status == 1)
        #expect(result.error == "❌ Failed to find directory named 'Build'.\n")
        #expect(result.output == "")
    }

    @Test("ignite run names the directory it was asked for")
    func runWithNamedDirectory() throws {
        let result = try run(["run", "--directory", "Output"])
        #expect(result.status == 1)
        #expect(result.error == "❌ Failed to find directory named 'Output'.\n")
    }

    @Test("Asking for help or the version is a success, written to standard output", arguments: [
        ["--help"], ["--version"], ["build", "--help"], ["new", "--help"], ["run", "--help"]
    ])
    func helpAndVersion(arguments: [String]) throws {
        let result = try run(arguments)
        #expect(result.status == 0)
        #expect(result.output.isEmpty == false)
        #expect(result.error == "")
    }

    @Test("The version is the one the tool declares")
    func version() throws {
        #expect(try run(["--version"]).output == "\(IgniteCLI.configuration.version)\n")
    }

    @Test("A command line the tool does not understand is a failure, explained on standard error", arguments: [
        ["publish"], ["new"], ["run", "--port", "eighty"], ["build", "--fast"]
    ])
    func usageErrors(arguments: [String]) throws {
        let result = try run(arguments)
        // 64 is EX_USAGE, which Argument Parser uses for a command line it cannot read.
        #expect(result.status == 64)
        #expect(result.error.hasPrefix("Error: "))
        #expect(result.output == "")
    }

    // MARK: - Installing

    /// The root of the package, where the Makefile is.
    private var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    @Test("make install that cannot install says so and fails, so a script does not carry on")
    func failedInstallIsAFailure() throws {
        // A directory nothing can be written into: whether or not the tool has been
        // built for release, `install` cannot put it there.
        let prefix = FileManager.default.temporaryDirectory.appending(path: "ignite-prefix-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: prefix, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o555])
        defer {
            do {
                try FileManager.default.removeItem(at: prefix)
            } catch {
                Issue.record("Could not remove \(prefix.path): \(error)")
            }
        }

        let result = try Process.execute(
            command: ["/usr/bin/make", "install", "PREFIX_DIR=\(prefix.path)"], timeout: 60, in: packageRoot)

        #expect(result.output.contains("❌ Installation failed."))
        #expect(result.output.contains("✅") == false)
        #expect(result.succeeded == false)
    }

    @Test("make install into a directory that cannot be created fails")
    func uncreatableInstallDirectoryIsAFailure() throws {
        let result = try Process.execute(
            command: ["/usr/bin/make", "install", "PREFIX_DIR=/dev/null/ignite"], timeout: 60, in: packageRoot)

        #expect(result.output.contains("❌ Unable to create install directory"))
        #expect(result.succeeded == false)
    }
}
