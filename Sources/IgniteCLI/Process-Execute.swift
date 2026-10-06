//
// Process-Execute.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// The ways running a command through `Process.execute(command:then:timeout:)`
/// can fail once the command itself has been launched.
enum ProcessExecutionError: LocalizedError {
    /// The command was still running when its time ran out, and was stopped.
    case timedOut(command: String, seconds: TimeInterval)

    /// The command ran, but reading what it wrote failed.
    case unreadableOutput(command: String, reason: String)

    /// No program by this name is on the user's `PATH`.
    case commandNotFound(String)

    /// There was no program to run: the argument list was empty.
    case emptyCommand

    /// A description of the failure, suitable for printing in a terminal.
    var errorDescription: String? {
        switch self {
        case .timedOut(let command, let seconds):
            "The command '\(command)' was stopped because it was still running after \(seconds.formatted()) seconds."
        case .unreadableOutput(let command, let reason):
            "The output of the command '\(command)' could not be read: \(reason)"
        case .commandNotFound(let program):
            "The command '\(program)' could not be found. Check that it is installed and on your PATH."
        case .emptyCommand:
            "There was no command to run."
        }
    }
}

/// A value shared between the thread that waits for a command and the
/// background threads that serve it.
// Justification: `value` is private and only read or written inside `lock`, so no two threads touch it at once.
private final class LockedBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    /// Runs `body` with exclusive access to the stored value.
    func withValue<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}

/// Empties one of a command's pipes in the background while the command runs,
/// so a command that writes more than a pipe holds never stalls waiting for
/// somebody to read it.
private struct PipeDrain: Sendable {
    /// Everything read so far.
    private let collected = LockedBox(Data())

    /// Why reading stopped early, if it did.
    private let failure = LockedBox<String?>(nil)

    /// Signalled once, when the pipe reaches end of file or reading fails.
    private let finished = DispatchSemaphore(value: 0)

    /// Starts draining `handle` immediately.
    ///
    /// The reading is done by a dispatch channel, which hands over each piece
    /// of output as a value this code owns. No buffer is lent to a system call
    /// here, so there is no pointer whose lifetime needs watching.
    init(reading handle: FileHandle) {
        // One serial queue per pipe, so pieces are collected in the order they were written.
        let queue = DispatchQueue(label: "ignite.pipe-drain")

        // The handle is captured by the channel's clean-up, not just its
        // descriptor, so the descriptor stays open for as long as the channel
        // is reading from it.
        let channel = DispatchIO(type: .stream, fileDescriptor: handle.fileDescriptor, queue: queue) { _ in
            withExtendedLifetime(handle) {}
        }

        // Hand over output as soon as any arrives rather than waiting for a
        // full buffer, so what has been written is already collected if the
        // wait for end of file has to be abandoned.
        channel.setLimit(lowWater: 1)

        channel.read(offset: 0, length: Int.max, queue: queue) { [collected, failure, finished] done, chunk, code in
            if let chunk, chunk.isEmpty == false {
                collected.withValue { $0.append(contentsOf: chunk) }
            }

            if code != 0 {
                let reason = String(cString: strerror(code))
                failure.withValue { $0 = reason }
            }

            // `done` arrives exactly once: at end of file, or when reading fails.
            if done {
                channel.close()
                finished.signal()
            }
        }
    }

    /// Waits for the pipe to close and returns what was read from it.
    ///
    /// A pipe closes only when every process holding its write end has let go,
    /// and a command can leave a descendant behind that never does. So this
    /// waits no later than `deadline`, then returns what has arrived so far.
    /// - Parameters:
    ///   - deadline: The moment to stop waiting for end of file.
    ///   - command: The command being read, used to describe a failure.
    /// - Returns: The text read from the pipe.
    /// - Throws: `ProcessExecutionError.unreadableOutput` if reading failed.
    func text(waitingUntil deadline: DispatchTime, command: String) throws -> String {
        _ = finished.wait(timeout: deadline)

        if let reason = failure.withValue({ $0 }) {
            throw ProcessExecutionError.unreadableOutput(command: command, reason: reason)
        }

        return String(decoding: collected.withValue { $0 }, as: UTF8.self)
    }
}

/// A command that has been launched, with both of its pipes being drained.
private struct LaunchedCommand {
    let command: String
    let process: Process
    let output: PipeDrain
    let error: PipeDrain

    /// Signalled once, when the process exits.
    let exited: DispatchSemaphore

    /// How long a stopped command is given to exit before it is killed, and
    /// then how long its pipes are given to close before reading gives up.
    static let grace: TimeInterval = 5

    /// Finds the program to run for the first word of a command.
    /// - Parameter program: A path containing a slash, used as it is, or a bare
    /// name, looked up in each directory of the user's `PATH` in order.
    /// - Returns: The program's location, or `nil` if no directory on `PATH` has
    /// an executable file by that name.
    private static func executableURL(for program: String) -> URL? {
        if program.contains("/") {
            return URL(fileURLWithPath: program)
        }

        let searchPath = ProcessInfo.processInfo.environment["PATH"] ?? ""

        for directory in searchPath.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(program)

            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }

    /// Launches a command and starts draining its pipes.
    ///
    /// The program is run directly, with each argument handed to it exactly as
    /// given. No shell reads the command, so nothing in an argument – a space, a
    /// semicolon, a quote – can be taken for anything but part of that argument.
    /// - Parameter arguments: The program to run, followed by its arguments.
    /// - Throws: `ProcessExecutionError` if there is no program to run, or whatever
    /// `Process.run()` throws if it cannot be launched.
    init(arguments: [String]) throws {
        guard let program = arguments.first else {
            throw ProcessExecutionError.emptyCommand
        }

        guard let executableURL = Self.executableURL(for: program) else {
            throw ProcessExecutionError.commandNotFound(program)
        }

        let command = arguments.joined(separator: " ")
        let process = Process()
        process.executableURL = executableURL
        process.arguments = Array(arguments.dropFirst())

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        let exited = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in exited.signal() }

        try process.run()

        self.command = command
        self.process = process
        self.exited = exited
        self.output = PipeDrain(reading: output.fileHandleForReading)
        self.error = PipeDrain(reading: error.fileHandleForReading)
    }

    /// Waits for the command to exit by itself.
    /// - Parameter timeout: How long to wait, in seconds.
    /// - Returns: `false` if the command was still running when time ran out.
    func waitForExit(upTo timeout: TimeInterval) -> Bool {
        exited.wait(timeout: .now() + timeout) == .success
    }

    /// Stops the command if it is still running: asks first, then insists.
    func stop() {
        guard process.isRunning else { return }

        process.terminate()

        if waitForExit(upTo: Self.grace) == false {
            kill(process.processIdentifier, SIGKILL)
            _ = waitForExit(upTo: Self.grace)
        }
    }

    /// Returns everything the command wrote, waiting a bounded time for its pipes to close.
    /// - Throws: `ProcessExecutionError.unreadableOutput` if either pipe could not be read.
    func collectedOutput() throws -> (output: String, error: String) {
        // One deadline for both pipes, so the wait is `grace` in total, not each.
        let deadline = DispatchTime.now() + Self.grace
        let outputString = try output.text(waitingUntil: deadline, command: command)
        let errorString = try error.text(waitingUntil: deadline, command: command)
        return (outputString, errorString)
    }

    /// Runs a command until it exits, stopping it if it outlives `timeout`.
    /// - Parameters:
    ///   - arguments: The program to run, followed by its arguments.
    ///   - timeout: How long the command may run, in seconds.
    /// - Returns: The contents of stdout and stderr as a tuple.
    /// - Throws: `ProcessExecutionError.timedOut` if the command had to be stopped.
    static func runToCompletion(
        arguments: [String],
        timeout: TimeInterval
    ) throws -> (output: String, error: String) {
        let launched = try LaunchedCommand(arguments: arguments)

        guard launched.waitForExit(upTo: timeout) else {
            launched.stop()
            throw ProcessExecutionError.timedOut(command: launched.command, seconds: timeout)
        }

        return try launched.collectedOutput()
    }
}

/// A Process extension that knows how to run a command and
/// return its result. To make things easier, this also knows how
/// to execute a subsequent command while the first one is
/// running, which is important for previewing on a local server.
///
/// Important: Commands are run directly rather than through a shell.
/// Each is an array – the program, then its arguments – and every
/// element reaches the program exactly as written.
extension Process {
    /// How long a command may run when its caller does not say: 30 minutes,
    /// which is generous for a first build of a site and all its dependencies.
    static let defaultTimeout: TimeInterval = 1800

    /// Runs a command, optionally followed by a second command.
    ///
    /// Both of the command's pipes are read while it runs. Without a subsequent
    /// command, the command is stopped and an error thrown if it is still running
    /// after `timeout`. With one, the first command is meant to keep running –
    /// it is the local server – so it is stopped when the user presses Return,
    /// and `timeout` bounds the subsequent command instead.
    ///
    /// Stopping reaches the program that was launched. A descendant it started
    /// can outlive it and keep a pipe open, which is why reading the pipes is
    /// also given only a few seconds to finish once the command has exited.
    /// - Parameters:
    ///   - arguments: The program to run, followed by its arguments. A bare
    ///   program name is looked up on the user's `PATH`.
    ///   - subsequentArguments: A second command to run a moment after the first
    ///   has started, used when previewing the local site in a web browser. Pass
    ///   `nil`, the default, to simply run the first command to completion. Pass
    ///   any array – even an empty one, which runs nothing – to keep the first
    ///   command running until the user presses Return.
    ///   - timeout: How long, in seconds, a command may run before it is stopped.
    /// - Returns: The contents of stdout and stderr as a tuple.
    /// - Throws: An error if a command cannot be found or launched, runs out of
    /// time, or its output cannot be read.
    @discardableResult
    static func execute(
        command arguments: [String],
        then subsequentArguments: [String]? = nil,
        timeout: TimeInterval = Process.defaultTimeout
    ) throws -> (output: String, error: String) {
        // With nothing to run afterwards this is a plain bounded run.
        guard let subsequentArguments else {
            return try LaunchedCommand.runToCompletion(arguments: arguments, timeout: timeout)
        }

        let launched = try LaunchedCommand(arguments: arguments)
        let subsequentFailure = LockedBox<(any Error)?>(nil)

        if subsequentArguments.isEmpty == false {
            // Add a tiny pause to make sure the first command
            // is up and running before we launch the next
            // command.
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                do {
                    _ = try LaunchedCommand.runToCompletion(arguments: subsequentArguments, timeout: timeout)
                } catch {
                    // Kept as well as logged: it is thrown once the first command stops.
                    logger.error("Follow-up command failed: \(error.localizedDescription, privacy: .public)")
                    subsequentFailure.withValue { $0 = error }
                }
            }
        }

        // The first command keeps running until the user presses Return.
        _ = readLine()
        launched.stop()

        // A subsequent command that failed is reported once the first has been
        // stopped, rather than leaving it running behind a thrown error.
        if let failure = subsequentFailure.withValue({ $0 }) {
            throw failure
        }

        return try launched.collectedOutput()
    }
}
