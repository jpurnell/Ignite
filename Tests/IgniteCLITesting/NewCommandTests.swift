//
// NewCommandTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import ArgumentParser
import Foundation
import Testing

@testable import IgniteCLI

/// Tests for `ignite new`: what it runs, and what it makes of each result.
@Suite("New Command Tests")
struct NewCommandTests {
    private static let starter = "https://github.com/twostraws/IgniteStarter"

    private func command(_ arguments: [String]) throws -> NewCommand {
        try #require(try NewCommand.parseAsRoot(arguments) as? NewCommand)
    }

    @Test("A template that is not an https address is refused before anything runs", arguments: [
        "git@example.com:me/site.git", "file:///tmp/site", "ftp://example.com/site", "example.com/site",
        "--upload-pack=touch /tmp/x"
    ])
    func insecureTemplate(template: String) throws {
        let fixture = try CommandFixture()
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) {
            try command(["MySite", "--template=\(template)"]).run(in: fixture.context)
        }
        #expect(fixture.errors.lines == ["❌ Template URL must start with https://"])
        #expect(fixture.output.contents == "")
        #expect(fixture.runner.commands == [])
    }

    @Test("An existing folder is not overwritten")
    func existingDirectory() throws {
        let fixture = try CommandFixture()
        defer { fixture.remove() }
        try fixture.write("mine", to: "MySite/keep.txt")

        #expect(throws: ExitCode.failure) { try command(["MySite"]).run(in: fixture.context) }
        #expect(fixture.errors.lines == ["❌ Directory 'MySite' is not empty; aborting."])
        #expect(fixture.output.contents == "")
        #expect(fixture.runner.commands == [])
    }

    @Test("A new site is cloned from the template, its history removed, and the next steps shown")
    func success() throws {
        let fixture = try CommandFixture { _ in
            // git reports its progress on standard error, and that is not a failure.
            CommandResult(output: "", error: "Cloning into 'MySite'...", status: 0)
        }
        defer { fixture.remove() }

        try command(["MySite"]).run(in: fixture.context)

        #expect(fixture.runner.commands == [
            ["git", "clone", "--", Self.starter, "MySite"],
            ["rm", "-rf", "--", "MySite/.git"]
        ])
        #expect(fixture.runner.invocations.map(\.timeout) == [600, 60])
        #expect(fixture.runner.invocations.map(\.directory) == [fixture.directory, fixture.directory])
        #expect(fixture.errors.contents == "")
        #expect(fixture.output.contents == """
        ⚙️  Creating a new Ignite site in 'MySite'...
        ✅ Success!

        Run the following commands to edit your site in Xcode:
        \tcd MySite
        \topen Package.swift

        Tip: If you want to build with Xcode, go to the Product menu and choose Destination > My Mac.


        """)
    }

    @Test("The template and the name are handed to git as arguments, never as options")
    func argumentsAreNotOptions() throws {
        let fixture = try CommandFixture()
        defer { fixture.remove() }

        try command(["--", "-site; rm -rf x", ]).run(in: fixture.context)
        #expect(fixture.runner.commands.first == ["git", "clone", "--", Self.starter, "-site; rm -rf x"])
    }

    @Test("A clone that fails says so and shows what git wrote")
    func cloneFailure() throws {
        let fixture = try CommandFixture { _ in
            CommandResult(output: "", error: "fatal: repository not found", status: 128)
        }
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) {
            try command(["MySite", "--template", "https://example.com/missing"]).run(in: fixture.context)
        }
        #expect(fixture.runner.commands == [["git", "clone", "--", "https://example.com/missing", "MySite"]])
        #expect(fixture.errors.lines == [
            "❌ Failed to create a new site. See errors below:", "fatal: repository not found"
        ])
        #expect(fixture.output.lines == ["⚙️  Creating a new Ignite site in 'MySite'..."])
    }

    @Test("A clone that fails without a word still fails the command")
    func silentCloneFailure() throws {
        let fixture = try CommandFixture { _ in .silentFailure(status: 1) }
        defer { fixture.remove() }

        #expect(throws: ExitCode.failure) { try command(["MySite"]).run(in: fixture.context) }
        // Nothing is cleaned up after a clone that did not happen.
        #expect(fixture.runner.commands.count == 1)
        #expect(fixture.errors.lines == ["❌ Failed to create a new site. See errors below:", ""])
        #expect(fixture.output.contents.contains("✅") == false)
    }

    @Test("A clone that writes 'fatal' or 'error:' and exits with 0 has not failed")
    func errorTextWithZeroStatus() throws {
        let fixture = try CommandFixture { _ in
            CommandResult(output: "", error: "warning: fatal is only a word; error: so is this", status: 0)
        }
        defer { fixture.remove() }

        try command(["MySite"]).run(in: fixture.context)
        #expect(fixture.runner.commands.count == 2)
        #expect(fixture.output.contents.contains("✅ Success!"))
        #expect(fixture.errors.contents == "")
    }

    @Test("A history that cannot be removed is reported, and the site still counts as made")
    func cleanupFailure() throws {
        let fixture = try CommandFixture { invocation in
            invocation.arguments.first == "rm" ? .silentFailure() : .success
        }
        defer { fixture.remove() }

        try command(["MySite"]).run(in: fixture.context)
        #expect(fixture.errors.lines == [
            "⚠️  Could not remove the template's Git history from 'MySite/.git'; delete it yourself."
        ])
        #expect(fixture.output.contents.contains("✅ Success!"))
    }

    @Test("When git cannot be run at all, the reason is thrown rather than swallowed")
    func gitMissing() throws {
        let fixture = try CommandFixture { _ in throw ProcessExecutionError.commandNotFound("git") }
        defer { fixture.remove() }

        #expect {
            try command(["MySite"]).run(in: fixture.context)
        } throws: { error in
            error.localizedDescription
                == "The command 'git' could not be found. Check that it is installed and on your PATH."
        }
        #expect(fixture.output.contents.contains("✅") == false)
    }
}
