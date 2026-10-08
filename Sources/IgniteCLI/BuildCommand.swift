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

        // Build the executable. Whether that worked is the compiler's exit status, not
        // what it printed: a warning can contain the text "error:", and a build can
        // fail without printing it. Its diagnostics are relayed either way.
        let build = try Process.execute(command: ["swift", "build"])

        guard build.succeeded else {
            logger.error("swift build exited with status \(build.status, privacy: .public).")
            // Everything it said, whether or not it called any of it an error.
            if build.error.isEmpty == false {
                errors.line(build.error)
            }

            errors.line("")
            errors.line("❌ Failed to build.")
            throw ExitCode.failure
        }

        relay(build.error, to: errors)

        // Generate the site, relaying its output and anything it reported.
        let generation = try Process.execute(command: ["swift", "run"])
        output.line(generation.output)

        guard generation.succeeded else {
            logger.error("swift run exited with status \(generation.status, privacy: .public).")
            // Everything it said, whether or not it called any of it an error.
            if generation.error.isEmpty == false {
                errors.line(generation.error)
            }

            errors.line("")
            errors.line("❌ Failed to generate HTML.")
            throw ExitCode.failure
        }

        relay(generation.error, to: errors)

        logger.info("Site built.")
        output.line("✅ Successfully built!")
    }

    /// Passes on what a successful command wrote to standard error, when that includes a
    /// compiler diagnostic.
    ///
    /// Progress lines such as "Building for debugging..." also arrive on standard error
    /// and are left out, as they always have been: only output containing a warning or
    /// an error is shown.
    /// - Parameters:
    ///   - diagnostics: Everything the command wrote to standard error.
    ///   - errors: Where to write it.
    private func relay(_ diagnostics: String, to errors: Output) {
        if diagnostics.contains("error:") || diagnostics.contains("warning:") {
            errors.line(diagnostics)
        }
    }
}
