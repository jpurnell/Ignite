//
// ProcessExecuteTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import IgniteCLI

/// Tests for the bounded process helper, against small real child processes.
///
/// Every child here is `/bin/sh` or a tool beside it running a few lines of script: no
/// compiler, no network, and nothing that outlives the test by more than a few seconds.
///
/// The suite runs one test at a time. Each test holds its thread while a child runs, and
/// Swift Testing runs tests on the concurrency pool, which has one thread for each core and
/// does not grow: a dozen of these at once would hold all of it and leave the dispatch
/// work the helper depends on – the follow-up command's timer – waiting behind them.
@Suite("Process Execute Tests", .serialized)
struct ProcessExecuteTests {
    private static let shell = "/bin/sh"

    /// A file in a new temporary directory, and a way to remove the directory.
    private func scratchFile(_ name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "ignite-process-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: name)
    }

    private func removeDirectory(of file: URL) {
        do {
            try FileManager.default.removeItem(at: file.deletingLastPathComponent())
        } catch {
            Issue.record("Could not remove \(file.path): \(error)")
        }
    }

    /// Reads the process ID a child wrote to a file.
    private func processID(in file: URL) throws -> pid_t {
        let text = try String(contentsOf: file, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        return try #require(pid_t(text))
    }

    /// Whether a process with this ID still exists.
    private func isRunning(_ processID: pid_t) -> Bool {
        kill(processID, 0) == 0
    }

    // MARK: - Results

    @Test("A command's two outputs and its exit status are returned separately")
    func outputsAndStatus() throws {
        let result = try Process.execute(command: [Self.shell, "-c", "echo out; echo err >&2; exit 0"], timeout: 20)
        #expect(result.output == "out\n")
        #expect(result.error == "err\n")
        #expect(result.status == 0)
        #expect(result.succeeded)
        #expect(result.stoppedByCaller == false)
    }

    @Test("A non-zero exit status is returned, not thrown, and is not success", arguments: [Int32(1), 2, 64, 127, 255])
    func failureStatus(status: Int32) throws {
        let result = try Process.execute(command: [Self.shell, "-c", "exit \(status)"], timeout: 20)
        #expect(result.status == status)
        #expect(result.succeeded == false)
    }

    @Test("A command that fails without writing anything has still failed")
    func silentFailure() throws {
        let result = try Process.execute(command: ["/usr/bin/false"], timeout: 20)
        #expect(result.output == "")
        #expect(result.error == "")
        #expect(result.succeeded == false)
    }

    @Test("A command that writes 'error:' and 'fatal' and exits with 0 has succeeded")
    func errorTextIsNotFailure() throws {
        let result = try Process.execute(
            command: [Self.shell, "-c", "echo 'error: fatal: not really' >&2; exit 0"], timeout: 20)
        #expect(result.error == "error: fatal: not really\n")
        #expect(result.succeeded)
    }

    @Test("A command ended by a signal reports the signal, which is not success")
    func signalStatus() throws {
        let result = try Process.execute(command: [Self.shell, "-c", "kill -9 $$"], timeout: 20)
        #expect(result.status == SIGKILL)
        #expect(result.succeeded == false)
    }

    // MARK: - Launching

    @Test("Arguments reach the program exactly as given: no shell reads them")
    func argumentsAreNotInterpreted() throws {
        let result = try Process.execute(
            command: ["/bin/echo", "a; echo b", "$HOME", "`id`", "x > y", "*"], timeout: 20)
        #expect(result.output == "a; echo b $HOME `id` x > y *\n")
    }

    @Test("A bare program name is found on the PATH")
    func bareNameIsFoundOnPath() throws {
        let result = try Process.execute(command: ["echo", "found"], timeout: 20)
        #expect(result.output == "found\n")
    }

    @Test("A command runs in the directory it is given")
    func directory() throws {
        let file = try scratchFile("marker.txt")
        defer { removeDirectory(of: file) }
        try "here".write(to: file, atomically: true, encoding: .utf8)

        let result = try Process.execute(
            command: ["/bin/cat", "marker.txt"], timeout: 20, in: file.deletingLastPathComponent())
        #expect(result.output == "here")
        #expect(result.succeeded)
    }

    @Test("A program that does not exist is an error that names it")
    func commandNotFound() {
        #expect {
            try Process.execute(command: ["ignite-no-such-program-7f3a", "x"], timeout: 20)
        } throws: { error in
            error.localizedDescription == """
            The command 'ignite-no-such-program-7f3a' could not be found. \
            Check that it is installed and on your PATH.
            """
        }
    }

    @Test("An empty command is an error, not a crash")
    func emptyCommand() {
        #expect {
            try Process.execute(command: [], timeout: 20)
        } throws: { error in
            error.localizedDescription == "There was no command to run."
        }
    }

    // MARK: - Pipes

    @Test("Both pipes are read while the command runs, so neither can fill and stall it")
    func concurrentDraining() throws {
        // Each stream gets far more than a pipe holds (64 KB), standard error first. A
        // reader that took the pipes one after the other would leave the command
        // blocked on the first, and this would end as a timeout instead.
        let script = """
        head -c 400000 /dev/zero | tr '\\0' e >&2
        head -c 400000 /dev/zero | tr '\\0' o
        head -c 400000 /dev/zero | tr '\\0' E >&2
        head -c 400000 /dev/zero | tr '\\0' O
        """
        let result = try Process.execute(command: [Self.shell, "-c", script], timeout: 60)

        #expect(result.succeeded)
        #expect(result.output.count == 800_000)
        #expect(result.error.count == 800_000)
        #expect(result.output == String(repeating: "o", count: 400_000) + String(repeating: "O", count: 400_000))
        #expect(result.error == String(repeating: "e", count: 400_000) + String(repeating: "E", count: 400_000))
    }

    @Test("Output is returned even when a descendant keeps the pipe open after the command exits")
    func descendantHoldingPipe() throws {
        // The shell exits at once; the `sleep` it leaves behind still holds both pipes
        // for a few seconds. Waiting for end of file would wait on the sleep.
        let clock = ContinuousClock()
        var result: CommandResult?
        let elapsed = try clock.measure {
            result = try Process.execute(command: [Self.shell, "-c", "sleep 9 & echo started"], timeout: 60)
        }

        #expect(result?.output == "started\n")
        #expect(result?.status == 0)
        // It gave up on the pipe after its grace period rather than waiting out the sleep.
        #expect(elapsed < .seconds(8.5))
    }

    @Test("Commands run at once from concurrent tasks each get their own output, all of it")
    func concurrentCommands() async throws {
        // More commands than the machine has cores, each waiting on a thread of the
        // concurrency pool. Reading the pipes must not depend on that pool having a
        // thread to spare, or output is silently lost once every thread is waiting.
        let count = max(16, ProcessInfo.processInfo.activeProcessorCount * 2)

        let outputs = try await withThrowingTaskGroup(of: (Int, CommandResult).self) { group in
            for index in 0..<count {
                group.addTask {
                    (index, try Process.execute(
                        command: [Self.shell, "-c", "echo out\(index); echo err\(index) >&2"], timeout: 60))
                }
            }

            var results = [Int: CommandResult]()
            for try await (index, result) in group {
                results[index] = result
            }
            return results
        }

        #expect(outputs.count == count)
        for index in 0..<count {
            #expect(outputs[index]?.output == "out\(index)\n")
            #expect(outputs[index]?.error == "err\(index)\n")
            #expect(outputs[index]?.status == 0)
        }
    }

    // MARK: - Time limits

    @Test("A command that outlives its time limit is stopped, and the error says so")
    func timeout() throws {
        let file = try scratchFile("pid")
        defer { removeDirectory(of: file) }

        #expect {
            try Process.execute(
                command: [Self.shell, "-c", "echo $$ > '\(file.path)'; exec sleep 60"], timeout: 1)
        } throws: { error in
            guard case ProcessExecutionError.timedOut(_, let seconds) = error else { return false }
            return seconds == 1
                && error.localizedDescription.hasSuffix("was stopped because it was still running after 1 seconds.")
        }

        // `exec` made the sleep the process that was launched; it is gone.
        #expect(isRunning(try processID(in: file)) == false)
    }

    @Test("A command that ignores the request to stop is killed")
    func killAfterTerminateIsIgnored() throws {
        let file = try scratchFile("pid")
        defer { removeDirectory(of: file) }

        // The shell ignores SIGTERM and loops; only SIGKILL ends it.
        let script = "trap '' TERM; echo $$ > '\(file.path)'; while :; do sleep 1; done"
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            #expect(throws: ProcessExecutionError.self) {
                try Process.execute(command: [Self.shell, "-c", script], timeout: 1)
            }
        }

        #expect(isRunning(try processID(in: file)) == false)
        // One second to time out, then the grace period it is given to stop by itself.
        #expect(elapsed >= .seconds(5.5))
        #expect(elapsed < .seconds(30))
    }

    // MARK: - A command that keeps running

    @Test("A command with a follow-up runs until it is told to stop, and says it was stopped")
    func stoppedByCaller() throws {
        let file = try scratchFile("followed-up")
        defer { removeDirectory(of: file) }

        let result = try Process.execute(
            command: [Self.shell, "-c", "echo serving; exec sleep 60"],
            then: ["/usr/bin/touch", file.path],
            timeout: 20,
            waitToStop: {
                // Stands in for the user pressing Return, once the follow-up has run.
                let deadline = Date().addingTimeInterval(15)
                while FileManager.default.fileExists(atPath: file.path) == false, Date() < deadline {
                    Thread.sleep(forTimeInterval: 0.05)
                }
            })

        #expect(FileManager.default.fileExists(atPath: file.path))
        #expect(result.output == "serving\n")
        #expect(result.stoppedByCaller)
        #expect(result.status == SIGTERM)
    }

    @Test("A command that ended by itself before it was told to stop reports its own status")
    func endedBeforeStop() throws {
        let result = try Process.execute(
            command: [Self.shell, "-c", "echo 'port in use' >&2; exit 3"],
            then: [],
            timeout: 20,
            waitToStop: { Thread.sleep(forTimeInterval: 0.5) })

        #expect(result.error == "port in use\n")
        #expect(result.status == 3)
        #expect(result.stoppedByCaller == false)
        #expect(result.succeeded == false)
    }

    @Test("A follow-up that cannot be run is reported once the first command has been stopped")
    func followUpFailure() throws {
        let file = try scratchFile("pid")
        defer { removeDirectory(of: file) }

        #expect {
            try Process.execute(
                command: [Self.shell, "-c", "echo $$ > '\(file.path)'; exec sleep 60"],
                then: ["ignite-no-such-program-7f3a"],
                timeout: 20,
                waitToStop: { Thread.sleep(forTimeInterval: 2) })
        } throws: { error in
            error.localizedDescription.hasPrefix("The command 'ignite-no-such-program-7f3a' could not be found.")
        }

        #expect(isRunning(try processID(in: file)) == false)
    }
}
