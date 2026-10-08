//
// BuildCommand.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import ArgumentParser
import Foundation

/// The command responsible for converting their site
/// code to HTML.
struct BuildCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Builds all the HTML for the current site."
    )

    /// Runs this command. Automatically called by Argument Parser.
    /// - Throws: `ExitCode.failure` when the site could not be built, so the tool exits
    /// with a non-zero status and a script that called it can tell.
    func run() throws {
        try run(output: .standard, errors: .standardError)
    }

    /// Builds the site, saying what happened on the outputs given.
    /// - Parameters:
    ///   - output: Receives progress, the site's own output, and the final result.
    ///   - errors: Receives the reasons a build could not finish, along with
    ///   whatever the compiler and the site wrote to standard error.
    /// - Throws: `ExitCode.failure` once the reason has been written to `errors`, when
    /// there is no package to build, it does not compile, or generating the site fails.
    func run(output: Output, errors: Output) throws {
        // Ensure we're in a valid directory.
        guard FileManager.default.fileExists(atPath: "./Package.swift") else {
            logger.error("No Package.swift in the current directory; nothing to build.")
            errors.line("❌ Can't find Package.swift in the current directory.")
            throw ExitCode.failure
        }

        output.line("⚙️  Building your site...")

        // Build executable and report errors & earnings
        let (_, error) = try Process.execute(command: ["swift", "build"])

        // If something went wrong, print a message then
        // bail out.
        if error.contains("error:") {
            logger.error("swift build reported errors.")
            errors.line(error)

            errors.line("")
            errors.line("❌ Failed to build.")
            throw ExitCode.failure
        } else if error.contains("warning:") {
            // Warnings can just be printed; they won't hold
            // up a successful build.
            errors.line(error)
        }

        // Execute site generation with output, and report errors & earnings
        let (siteOutput, runError) = try Process.execute(command: ["swift", "run"])
        output.line(siteOutput)

        // If something went wrong, print a message then
        // bail out.
        if runError.contains("error:") {
            logger.error("swift run reported errors while generating the site.")
            errors.line(runError)

            errors.line("")
            errors.line("❌ Failed to generate HTML.")
            throw ExitCode.failure
        } else if runError.contains("warning:") {
            // Warnings can just be printed; they won't hold
            // up a successful build.
            errors.line(runError)
        }

        logger.info("Site built.")
        output.line("✅ Successfully built!")
    }
}
