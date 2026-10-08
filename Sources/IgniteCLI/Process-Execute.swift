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
    /// The reading is done on a thread of its own. It used to be done by a dispatch
    /// channel, whose work needs a thread from the system's shared pool; when every one
    /// of those was waiting – as happens when commands are run from many concurrent
    /// tasks at once – nothing was read before the wait below gave up, and a command
    /// that had worked was reported as having written nothing. A thread that belongs to
    /// this pipe cannot be kept from it.
    ///
    /// Each read fills a buffer that lives only for that read, and what was read is
    /// copied out of it before the next.
    init(reading handle: FileHandle) {
        let thread = Thread { [collected, failure, finished] in
            // The handle is held for as long as the thread reads, so its descriptor
            // stays open.
            withExtendedLifetime(handle) {
                var isOpen = true

                while isOpen {
                    switch Self.readOnce(from: handle.fileDescriptor) {
                    case .bytes(let chunk):
                        collected.withValue { $0.append(chunk) }
                    case .interrupted:
                        // A signal arrived before anything was read; ask again.
                        continue
                    case .endOfFile:
                        // Every process holding the other end has let go.
                        isOpen = false
                    case .failed(let reason):
                        failure.withValue { $0 = reason }
                        isOpen = false
                    }
                }
            }

            // Signalled exactly once: at end of file, or when reading fails.
            finished.signal()
        }

        thread.name = "ignite.pipe-drain"
        thread.start()
    }

    /// The most to take from the pipe in one read: as much as a pipe holds.
    private static let chunkSize = 65_536

    /// What one read from a pipe came back with.
    private enum ReadResult {
        /// Some output. A read never waits to fill its buffer.
        case bytes(Data)

        /// Nothing yet: the read was interrupted by a signal and should be repeated.
        case interrupted

        /// The pipe is closed and everything written to it has been read.
        case endOfFile

        /// The read failed, for the reason given.
        case failed(String)
    }

    /// Reads whatever a pipe has, waiting only if it has nothing.
    ///
    /// `read` returns as soon as anything has been written, rather than waiting for a
    /// full buffer, so what has arrived is already collected if the wait for end of
    /// file has to be abandoned. The buffer is created, filled and copied out of here.
    /// It is handed to `read` as an in-out argument, which lends it for that call alone:
    /// no pointer to it is ever held, so there is none whose lifetime needs watching.
    /// - Parameter descriptor: The reading end of the pipe.
    /// - Returns: What was read, or why nothing was.
    private static func readOnce(from descriptor: Int32) -> ReadResult {
        var buffer = [UInt8](repeating: 0, count: chunkSize)
        let count = read(descriptor, &buffer, buffer.count)
        // Taken at once, before anything else can set it.
        let code = errno

        if count > 0 {
            return .bytes(Data(buffer[..<count]))
        } else if count == 0 {
            return .endOfFile
        } else if code == EINTR {
            return .interrupted
        } else {
            return .failed(String(cString: strerror(code)))
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

/// What a command wrote and how it ended.
struct CommandResult {
    /// Everything the command wrote to standard output.
    let output: String

    /// Everything the command wrote to standard error.
    let error: String

    /// The command's exit status: 0 for success. A command ended by a signal reports
    /// the signal's number, and one that could not be confirmed to have exited reports -1,
    /// so neither is mistaken for success.
    let status: Int32

    /// Whether the command was still running when its caller stopped it.
    ///
    /// Only a command that is meant to keep running – the local server – is ever stopped
    /// this way, and its status is then the signal that stopped it, not a verdict on it.
    /// When this is `false` the command ended by itself and `status` is its own.
    let stoppedByCaller: Bool

    /// Whether the command exited normally with a status of 0.
    ///
    /// This is the only reliable sign that a command worked. What it writes to standard
    /// error is not: tools print warnings that mention errors, and fail without a word.
    var succeeded: Bool { status == 0 }

    /// Creates the result of a command.
    /// - Parameters:
    ///   - output: Everything the command wrote to standard output.
    ///   - error: Everything the command wrote to standard error.
    ///   - status: The command's exit status.
    ///   - stoppedByCaller: Whether the command was stopped rather than ending by itself.
    init(output: String, error: String, status: Int32, stoppedByCaller: Bool = false) {
        self.output = output
        self.error = error
        self.status = status
        self.stoppedByCaller = stoppedByCaller
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
    /// - Parameters:
    ///   - arguments: The program to run, followed by its arguments.
    ///   - directory: The directory to run it in, or `nil` for this process's own.
    /// - Throws: `ProcessExecutionError` if there is no program to run, or whatever
    /// `Process.run()` throws if it cannot be launched.
    init(arguments: [String], in directory: URL? = nil) throws {
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

        if let directory {
            process.currentDirectoryURL = directory
        }

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
    /// - Returns: `true` if the command was running and had to be stopped, `false` if it
    /// had already ended by itself.
    @discardableResult
    func stop() -> Bool {
        guard process.isRunning else { return false }

        process.terminate()

        if waitForExit(upTo: Self.grace) == false {
            kill(process.processIdentifier, SIGKILL)
            _ = waitForExit(upTo: Self.grace)
        }

        return true
    }

    /// Returns everything the command wrote and its exit status, waiting a bounded time
    /// for its pipes to close.
    /// - Parameter stoppedByCaller: Whether the command was stopped rather than ending by itself.
    /// - Throws: `ProcessExecutionError.unreadableOutput` if either pipe could not be read.
    func collectedOutput(stoppedByCaller: Bool = false) throws -> CommandResult {
        // One deadline for both pipes, so the wait is `grace` in total, not each.
        let deadline = DispatchTime.now() + Self.grace
        let outputString = try output.text(waitingUntil: deadline, command: command)
        let errorString = try error.text(waitingUntil: deadline, command: command)

        // A process that is somehow still running has no status to read yet.
        let status = process.isRunning ? -1 : process.terminationStatus
        return CommandResult(
            output: outputString, error: errorString, status: status, stoppedByCaller: stoppedByCaller)
    }

    /// Runs a command until it exits, stopping it if it outlives `timeout`.
    /// - Parameters:
    ///   - arguments: The program to run, followed by its arguments.
    ///   - timeout: How long the command may run, in seconds.
    ///   - directory: The directory to run it in, or `nil` for this process's own.
    /// - Returns: What the command wrote, and its exit status.
    /// - Throws: `ProcessExecutionError.timedOut` if the command had to be stopped.
    static func runToCompletion(
        arguments: [String],
        timeout: TimeInterval,
        in directory: URL? = nil
    ) throws -> CommandResult {
        let launched = try LaunchedCommand(arguments: arguments, in: directory)

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
    ///   - directory: The directory to run the commands in, or `nil`, the default, for
    ///   this process's own.
    ///   - waitToStop: With a subsequent command, what to wait for before stopping the
    ///   first. It returns when the first command should stop. The default waits for
    ///   the user to press Return.
    /// - Returns: What the command wrote to stdout and stderr, and its exit status.
    /// A command that runs and exits with a non-zero status is returned, not thrown:
    /// check `succeeded`.
    /// - Throws: An error if a command cannot be found or launched, runs out of
    /// time, or its output cannot be read.
    @discardableResult
    static func execute(
        command arguments: [String],
        then subsequentArguments: [String]? = nil,
        timeout: TimeInterval = Process.defaultTimeout,
        in directory: URL? = nil,
        waitToStop: @Sendable () -> Void = { _ = readLine() }
    ) throws -> CommandResult {
        // With nothing to run afterwards this is a plain bounded run.
        guard let subsequentArguments else {
            return try LaunchedCommand.runToCompletion(arguments: arguments, timeout: timeout, in: directory)
        }

        let launched = try LaunchedCommand(arguments: arguments, in: directory)
        let subsequentFailure = LockedBox<(any Error)?>(nil)

        if subsequentArguments.isEmpty == false {
            // Add a tiny pause to make sure the first command
            // is up and running before we launch the next
            // command.
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                do {
                    _ = try LaunchedCommand.runToCompletion(
                        arguments: subsequentArguments, timeout: timeout, in: directory)
                } catch {
                    // Kept as well as logged: it is thrown once the first command stops.
                    logger.error("Follow-up command failed: \(error.localizedDescription, privacy: .public)")
                    subsequentFailure.withValue { $0 = error }
                }
            }
        }

        // The first command keeps running until the user presses Return.
        waitToStop()
        let stoppedByCaller = launched.stop()

        // A subsequent command that failed is reported once the first has been
        // stopped, rather than leaving it running behind a thrown error.
        if let failure = subsequentFailure.withValue({ $0 }) {
            throw failure
        }

        return try launched.collectedOutput(stoppedByCaller: stoppedByCaller)
    }
}
