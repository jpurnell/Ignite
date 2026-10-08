//
// NewCommand.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import ArgumentParser
import Foundation

/// The command responsible for creating new Ignite sites.
/// This clones the starter repository from GitHub.
struct NewCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Creates a new Ignite site in a named folder."
    )

    @Option(name: .shortAndLong, help: "The Git repository to clone.")
    var template: String = "https://github.com/twostraws/IgniteStarter"

    /// Required argument: the name of the site to create.
    @Argument(help: "The name of the subfolder where you want the new site to be made. This must not currently exist.")
    var name: String

    /// Runs this command. Automatically called by Argument Parser.
    /// - Throws: `ExitCode.failure` when the site could not be created, so the tool exits
    /// with a non-zero status and a script that called it can tell.
    func run() throws {
        try run(output: .standard, errors: .standardError)
    }

    /// Creates the site, saying what happened on the outputs given.
    /// - Parameters:
    ///   - output: Receives progress and, on success, what to do next.
    ///   - errors: Receives the reasons a site could not be created.
    /// - Throws: `ExitCode.failure` once the reason has been written to `errors`, when
    /// the template is not an https:// address, the folder already exists, or cloning fails.
    func run(output: Output, errors: Output) throws {
        guard template.starts(with: "https://") else {
            logger.error("Refused template \(template, privacy: .public): not an https:// address.")
            errors.line("❌ Template URL must start with https://")
            throw ExitCode.failure
        }

        // Ensure we aren't trying to overwrite an existing site.
        guard FileManager.default.fileExists(atPath: "./\(name)") == false else {
            logger.error("Refused to create \(name, privacy: .public): it already exists.")
            errors.line("❌ Directory '\(name)' is not empty; aborting.")
            throw ExitCode.failure
        }

        // Clone from remote Git repository
        output.line("⚙️  Creating a new Ignite site in '\(name)'...")
        let result = try Process.execute(command: ["git", "clone", "--", template, name], timeout: 600)

        guard result.error.contains("fatal") == false else {
            logger.error("git clone of \(template, privacy: .public) failed.")
            errors.line("❌ Failed to create a new site. See errors below:")
            errors.line(result.error)
            throw ExitCode.failure
        }

        // If everything worked, remove the Git history
        // for the IgniteStarter repo to avoid confusion.
        try Process.execute(command: ["rm", "-rf", "--", "\(name)/.git"], timeout: 60)
        logger.info("Created a new site in \(name, privacy: .public).")
        output.line("✅ Success!")

        let nextSteps = "\nRun the following commands to edit your site in Xcode:\n\tcd \(name)\n\topen Package.swift\n"
        output.line(nextSteps)
        let tip = "Tip: If you want to build with Xcode, go to the Product menu and choose Destination > My Mac.\n"
        output.line(tip)
    }
}
