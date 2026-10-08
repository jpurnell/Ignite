//
// CommandContext.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// How a command runs the programs it depends on: `swift`, `git`, the local server.
///
/// The tool itself uses ``live``, which launches the program with ``Foundation/Process``.
/// A test passes a runner of its own, so a command's logic – what it runs, in what
/// order, and what it makes of each result – can be exercised without a compiler, a
/// network or a web server.
struct CommandRunner: Sendable {
    /// One request to run a program.
    struct Invocation: Sendable, Equatable {
        /// The program to run, followed by its arguments.
        var arguments: [String]

        /// A second command to start once the first is running, or `nil` to run the
        /// first to completion. See `Process.execute(command:then:timeout:in:waitToStop:)`.
        var followUp: [String]?

        /// How long, in seconds, the command may run.
        var timeout: TimeInterval

        /// The directory to run the command in.
        var directory: URL
    }

    private let body: @Sendable (Invocation) throws -> CommandResult

    /// Creates a runner that answers each request with `body`.
    init(_ body: @escaping @Sendable (Invocation) throws -> CommandResult) {
        self.body = body
    }

    /// Runs programs for real, through the bounded process helper.
    static let live = CommandRunner { invocation in
        try Process.execute(
            command: invocation.arguments,
            then: invocation.followUp,
            timeout: invocation.timeout,
            in: invocation.directory)
    }

    /// Runs a program.
    /// - Parameter invocation: What to run, for how long and where.
    /// - Returns: What the program wrote, and its exit status.
    func run(_ invocation: Invocation) throws -> CommandResult {
        try body(invocation)
    }
}

/// Everything a command reaches outside itself, so that each of them can be replaced.
struct CommandContext: Sendable {
    /// Receives progress and results.
    var output: Output = .standard

    /// Receives the reasons a command could not finish.
    var errors: Output = .standardError

    /// Runs the programs the command depends on.
    var runner: CommandRunner = .live

    /// The directory the command works in: the one the tool was started from.
    var workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    /// The path the tool was started by, used to find the server script installed beside it.
    var toolPath = ProcessInfo.processInfo.arguments.first ?? ""

    /// Runs a program in the working directory.
    /// - Parameters:
    ///   - arguments: The program to run, followed by its arguments.
    ///   - followUp: A second command to start once the first is running, or `nil`.
    ///   - timeout: How long, in seconds, the command may run.
    /// - Returns: What the program wrote, and its exit status.
    func execute(
        _ arguments: [String],
        then followUp: [String]? = nil,
        timeout: TimeInterval = Process.defaultTimeout
    ) throws -> CommandResult {
        try runner.run(CommandRunner.Invocation(
            arguments: arguments, followUp: followUp, timeout: timeout, directory: workingDirectory))
    }

    /// Whether a file or directory exists at a path within the working directory.
    func fileExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: workingDirectory.appending(path: path).path)
    }
}
