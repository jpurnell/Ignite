//
// BuildCommandTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import ArgumentParser
import Foundation
import Testing

@testable import IgniteCLI

/// Tests for `ignite build`: what it runs, and what it makes of each result.
@Suite("Build Command Tests")
struct BuildCommandTests {
    private func command() throws -> BuildCommand {
        try #require(try BuildCommand.parseAsRoot([]) as? BuildCommand)
    }

    @Test("With no Package.swift the build fails, says why on the errors output, and runs nothing")
    func noPackage() throws {
        let fixture = try CommandFixture()
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.errors.lines == ["❌ Can't find Package.swift in the current directory."])
        #expect(fixture.output.contents == "")
        #expect(fixture.runner.commands == [])
    }

    @Test("A site that builds and generates reports success and exits normally")
    func success() throws {
        let fixture = try CommandFixture { invocation in
            invocation.arguments == ["swift", "run"]
                ? CommandResult(output: "Published 3 pages.", error: "Building for debugging...", status: 0)
                : CommandResult(output: "", error: "Building for debugging...", status: 0)
        }
        defer { fixture.remove() }
        try fixture.write("// swift-tools-version: 6.2", to: "Package.swift")

        try command().run(in: fixture.context)

        #expect(fixture.runner.commands == [["swift", "build"], ["swift", "run"]])
        #expect(fixture.runner.invocations.map(\.directory) == [fixture.directory, fixture.directory])
        #expect(fixture.runner.invocations.map(\.followUp) == [nil, nil])
        #expect(fixture.output.lines == ["⚙️  Building your site...", "Published 3 pages.", "✅ Successfully built!"])
        // Progress on standard error is not a diagnostic and is not relayed.
        #expect(fixture.errors.contents == "")
    }

    @Test("A compile error fails the build and shows everything the compiler said")
    func compileError() throws {
        let diagnostics = "main.swift:3:1: error: cannot find 'x' in scope"
        let fixture = try CommandFixture { _ in CommandResult(output: "", error: diagnostics, status: 1) }
        defer { fixture.remove() }
        try fixture.write("", to: "Package.swift")

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.runner.commands == [["swift", "build"]])
        #expect(fixture.errors.lines == [diagnostics, "", "❌ Failed to build."])
        #expect(fixture.output.lines == ["⚙️  Building your site..."])
    }

    @Test("A build that fails without a word still fails the command", arguments: [Int32(1), 2, 9, -1])
    func silentBuildFailure(status: Int32) throws {
        let fixture = try CommandFixture { _ in .silentFailure(status: status) }
        defer { fixture.remove() }
        try fixture.write("", to: "Package.swift")

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.runner.commands == [["swift", "build"]])
        #expect(fixture.errors.lines == ["", "❌ Failed to build."])
        #expect(fixture.output.contents.contains("✅") == false)
    }

    @Test("A build that prints 'error:' and exits with 0 has not failed")
    func errorTextWithZeroStatus() throws {
        let warning = "warning: the text 'error: not really' appears in this warning"
        let fixture = try CommandFixture { invocation in
            invocation.arguments == ["swift", "build"]
                ? CommandResult(output: "", error: warning, status: 0)
                : .success
        }
        defer { fixture.remove() }
        try fixture.write("", to: "Package.swift")

        try command().run(in: fixture.context)

        #expect(fixture.runner.commands == [["swift", "build"], ["swift", "run"]])
        #expect(fixture.output.lines == ["⚙️  Building your site...", "", "✅ Successfully built!"])
        // The diagnostic is passed on; it just does not decide the outcome.
        #expect(fixture.errors.lines == [warning])
    }

    @Test("A site that fails while generating fails the command and shows what it wrote")
    func generationFailure() throws {
        let fixture = try CommandFixture { invocation in
            invocation.arguments == ["swift", "run"]
                ? CommandResult(output: "Publishing...", error: "Fatal: no layout", status: 1)
                : .success
        }
        defer { fixture.remove() }
        try fixture.write("", to: "Package.swift")

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.runner.commands == [["swift", "build"], ["swift", "run"]])
        #expect(fixture.output.lines == ["⚙️  Building your site...", "Publishing..."])
        #expect(fixture.errors.lines == ["Fatal: no layout", "", "❌ Failed to generate HTML."])
    }

    @Test("A site that exits with a failure and no message fails the command")
    func silentGenerationFailure() throws {
        let fixture = try CommandFixture { invocation in
            invocation.arguments == ["swift", "run"] ? .silentFailure() : .success
        }
        defer { fixture.remove() }
        try fixture.write("", to: "Package.swift")

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.errors.lines == ["", "❌ Failed to generate HTML."])
        #expect(fixture.output.contents.contains("✅") == false)
    }

    @Test("A site that prints 'error:' while generating and exits with 0 has not failed")
    func generationErrorTextWithZeroStatus() throws {
        let fixture = try CommandFixture { invocation in
            invocation.arguments == ["swift", "run"]
                ? CommandResult(output: "Done.", error: "warning: 2 pages mention 'error:'", status: 0)
                : .success
        }
        defer { fixture.remove() }
        try fixture.write("", to: "Package.swift")

        try command().run(in: fixture.context)
        #expect(fixture.output.lines == ["⚙️  Building your site...", "Done.", "✅ Successfully built!"])
        #expect(fixture.errors.lines == ["warning: 2 pages mention 'error:'"])
    }

    @Test("When swift cannot be run at all, the reason is thrown rather than swallowed")
    func compilerMissing() throws {
        let fixture = try CommandFixture { _ in throw ProcessExecutionError.commandNotFound("swift") }
        defer { fixture.remove() }
        try fixture.write("", to: "Package.swift")

        #expect {
            try command().run(in: fixture.context)
        } throws: { error in
            error.localizedDescription
                == "The command 'swift' could not be found. Check that it is installed and on your PATH."
        }
        #expect(fixture.output.contents.contains("✅") == false)
    }
}
