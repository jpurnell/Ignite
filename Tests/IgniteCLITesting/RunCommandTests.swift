//
// RunCommandTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import ArgumentParser
import Foundation
import Testing

@testable import IgniteCLI

/// Tests for `ignite run`: what it runs, and what it makes of each result.
@Suite("Run Command Tests")
struct RunCommandTests {
    private func command(_ arguments: [String] = []) throws -> RunCommand {
        try #require(try RunCommand.parseAsRoot(arguments) as? RunCommand)
    }

    /// A fixture with a built site and the server script installed beside the tool.
    /// - Parameters:
    ///   - busyPorts: The ports `lsof` reports a server on.
    ///   - server: What running the server returns once it stops.
    private func servingFixture(
        busyPorts: Set<Int> = [],
        server: CommandResult = CommandResult(output: "", error: "", status: 15, stoppedByCaller: true)
    ) throws -> CommandFixture {
        let fixture = try CommandFixture { invocation in
            if invocation.arguments.first == "lsof" {
                let port = invocation.arguments.last.flatMap { Int($0.dropFirst("tcp:".count)) } ?? 0
                return CommandResult(output: busyPorts.contains(port) ? "4242\n" : "", error: "", status: 0)
            }
            return server
        }
        try fixture.write("<html></html>", to: "Build/index.html")
        try fixture.write("# server", to: "bin/ignite-server.py")
        return fixture
    }

    private func serverScript(in fixture: CommandFixture) -> String {
        fixture.directory.appending(path: "bin/ignite-server.py").path
    }

    // MARK: - Failures

    @Test("With no build directory there is nothing to serve")
    func noDirectory() throws {
        let fixture = try CommandFixture()
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.errors.lines == ["❌ Failed to find directory named 'Build'."])
        #expect(fixture.output.contents == "")
        #expect(fixture.runner.commands == [])
    }

    @Test("The directory named on the command line is the one looked for")
    func namedDirectoryMissing() throws {
        let fixture = try servingFixture()
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) { try command(["--directory", "Output"]).run(in: fixture.context) }
        #expect(fixture.errors.lines == ["❌ Failed to find directory named 'Output'."])
    }

    @Test("When every port up to 8999 is taken, the command fails without starting a server")
    func noFreePort() throws {
        let fixture = try servingFixture(busyPorts: Set(8000..<9000))
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) { try command(["--port", "8990"]).run(in: fixture.context) }
        #expect(fixture.errors.lines == ["❌ No available ports found in range 8000-8999."])
        #expect(fixture.output.contents == "")
        #expect(fixture.runner.commands == (8990..<9000).map { ["lsof", "-t", "-i", "tcp:\($0)"] })
    }

    @Test("A missing server script fails the command and says how to reinstall")
    func missingServerScript() throws {
        let fixture = try CommandFixture { _ in .success }
        defer { fixture.remove() }
        try fixture.write("<html></html>", to: "Build/index.html")

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.errors.lines == [
            "❌ Critical server script missing: \(serverScript(in: fixture))",
            "   This suggests a corrupted installation. Please reinstall with:",
            "   make clean && make install"
        ])
        #expect(fixture.output.contents == "")
        #expect(fixture.runner.commands == [["lsof", "-t", "-i", "tcp:8000"]])
    }

    @Test("A server that ends with a failure before it is stopped fails the command and shows why",
          arguments: [Int32(1), 2, 127])
    func serverDies(status: Int32) throws {
        let fixture = try servingFixture(
            server: CommandResult(output: "", error: "OSError: [Errno 48] Address already in use", status: status))
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.errors.lines == [
            "OSError: [Errno 48] Address already in use",
            "",
            "❌ The local web server stopped with an error (exit status \(status))."
        ])
    }

    @Test("A server that ends with a failure and no message still fails the command")
    func serverDiesSilently() throws {
        let fixture = try servingFixture(server: .silentFailure())
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) { try command().run(in: fixture.context) }
        #expect(fixture.errors.lines == ["", "❌ The local web server stopped with an error (exit status 1)."])
    }

    // MARK: - Success

    @Test("The server is started on the first free port and stopping it is a normal exit")
    func success() throws {
        let fixture = try servingFixture()
        defer { fixture.remove() }

        try command().run(in: fixture.context)

        #expect(fixture.runner.commands == [
            ["lsof", "-t", "-i", "tcp:8000"],
            ["python3", serverScript(in: fixture), "-d", "Build", "8000"]
        ])
        // An empty follow-up is what keeps the server running until Return is pressed.
        #expect(fixture.runner.invocations.last?.followUp == [])
        #expect(fixture.runner.invocations.last?.directory == fixture.directory)
        #expect(fixture.output.lines.first == "✅ Starting local web server on http://localhost:8000")
        #expect(fixture.output.lines.last == "Press ↵ Return to exit.")
        #expect(fixture.errors.contents == "")
    }

    @Test("A server that was stopped by the signal sent to it has not failed", arguments: [Int32(15), 9, 2])
    func stoppedServerIsNotAFailure(status: Int32) throws {
        let fixture = try servingFixture(
            server: CommandResult(output: "", error: "Keyboard interrupt", status: status, stoppedByCaller: true))
        defer { fixture.remove() }

        try command().run(in: fixture.context)
        #expect(fixture.errors.contents == "")
    }

    @Test("A server that ends by itself with status 0 has not failed")
    func serverEndsCleanly() throws {
        let fixture = try servingFixture(server: .success)
        defer { fixture.remove() }

        try command().run(in: fixture.context)
        #expect(fixture.errors.contents == "")
    }

    @Test("A busy port is passed over for the next free one")
    func busyPort() throws {
        let fixture = try servingFixture(busyPorts: [8000, 8001])
        defer { fixture.remove() }

        try command().run(in: fixture.context)
        #expect(fixture.runner.commands.last == ["python3", serverScript(in: fixture), "-d", "Build", "8002"])
        #expect(fixture.output.lines.first == "✅ Starting local web server on http://localhost:8002")
    }

    @Test("A site published for a subdirectory is served under it")
    func subsite() throws {
        let fixture = try servingFixture()
        defer { fixture.remove() }
        try fixture.write(
            #"<html><head><link href="https://example.com/docs/" rel="canonical" /></head></html>"#,
            to: "Build/index.html")

        try command(["--preview"]).run(in: fixture.context)

        #expect(fixture.runner.commands.last
            == ["python3", serverScript(in: fixture), "-d", "Build", "-s", "/docs", "8000"])
        #expect(fixture.runner.invocations.last?.followUp == ["open", "http://localhost:8000/docs"])
        #expect(fixture.output.lines.first == "✅ Starting local web server on http://localhost:8000/docs")
    }

    @Test("A site at the root of its host is served at the root", arguments: [
        "https://example.com", "https://example.com/", "not an address at all", "about:blank", "docs"
    ])
    func rootSite(canonical: String) throws {
        let fixture = try servingFixture()
        defer { fixture.remove() }
        try fixture.write(#"<link href="\#(canonical)" rel="canonical" />"#, to: "Build/index.html")

        try command(["--preview"]).run(in: fixture.context)
        #expect(fixture.runner.commands.last == ["python3", serverScript(in: fixture), "-d", "Build", "8000"])
        #expect(fixture.runner.invocations.last?.followUp == ["open", "http://localhost:8000"])
    }
}
