//
// CommandTestSupport.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import IgniteCLI

/// Collects what a command writes to one of its outputs.
// Justification: `text` is the only mutable state and every read or write of it holds `lock`.
final class CapturedOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var text = ""

    /// An output that appends to this capture.
    var output: Output {
        Output { [self] piece in
            lock.lock()
            defer { lock.unlock() }
            text += piece
        }
    }

    /// Everything written so far.
    var contents: String {
        lock.lock()
        defer { lock.unlock() }
        return text
    }

    /// Everything written so far, as lines, without the final line break.
    var lines: [String] {
        var lines = contents.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        if lines.last == "" { lines.removeLast() }
        return lines
    }
}

/// Stands in for `swift`, `git` and the rest: answers each command from a closure and
/// keeps a record of what was asked for.
// Justification: `recorded` is the only mutable state and every read or write of it holds `lock`.
final class ScriptedRunner: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [CommandRunner.Invocation] = []
    private let answer: @Sendable (CommandRunner.Invocation) throws -> CommandResult

    /// Creates a runner that answers every command with `answer`.
    init(_ answer: @escaping @Sendable (CommandRunner.Invocation) throws -> CommandResult) {
        self.answer = answer
    }

    /// The runner to hand to a command.
    var runner: CommandRunner {
        CommandRunner { [self] invocation in
            lock.lock()
            recorded.append(invocation)
            lock.unlock()
            return try answer(invocation)
        }
    }

    /// Every request made so far, in order.
    var invocations: [CommandRunner.Invocation] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    /// The argument lists of every request made so far, in order.
    var commands: [[String]] { invocations.map(\.arguments) }
}

/// A command's surroundings for one test: a directory of its own, captured outputs and
/// a scripted runner.
struct CommandFixture {
    let directory: URL
    let output = CapturedOutput()
    let errors = CapturedOutput()
    let runner: ScriptedRunner

    /// Creates a fixture in a new, empty temporary directory.
    /// - Parameter answer: How the scripted runner answers each command. The default
    /// answers every command with success and no output.
    init(
        answer: @escaping @Sendable (CommandRunner.Invocation) throws -> CommandResult = { _ in .success }
    ) throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "ignite-cli-\(UUID().uuidString)")
            .resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        runner = ScriptedRunner(answer)
    }

    /// The context to run a command in.
    var context: CommandContext {
        CommandContext(
            output: output.output,
            errors: errors.output,
            runner: runner.runner,
            workingDirectory: directory,
            toolPath: directory.appending(path: "bin/ignite").path)
    }

    /// Writes a file in the fixture's directory, creating the directories above it.
    func write(_ contents: String, to path: String) throws {
        let file = directory.appending(path: path)
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: file, atomically: true, encoding: .utf8)
    }

    /// Removes the fixture's directory.
    func remove() {
        do {
            try FileManager.default.removeItem(at: directory)
        } catch {
            Issue.record("Could not remove \(directory.path): \(error)")
        }
    }
}

extension CommandResult {
    /// A command that worked and said nothing.
    static let success = CommandResult(output: "", error: "", status: 0)

    /// A command that exited with a status and wrote nothing at all.
    static func silentFailure(status: Int32 = 1) -> CommandResult {
        CommandResult(output: "", error: "", status: status)
    }
}
