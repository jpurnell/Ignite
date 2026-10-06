//
// PublishingOutputTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Collects everything written to a ``PublishingOutput`` so a test can read it back.
// Justification: `chunks` is the only mutable state and every read or write of it holds `lock`.
private final class CapturedOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var chunks = [String]()

    /// An output that records each write here rather than showing it.
    var output: PublishingOutput {
        PublishingOutput { text in
            self.lock.lock()
            defer { self.lock.unlock() }
            self.chunks.append(text)
        }
    }

    /// Each write in order, exactly as it was handed to the sink.
    var writes: [String] {
        lock.lock()
        defer { lock.unlock() }
        return chunks
    }

    /// Everything written, as the terminal would have received it.
    var text: String {
        writes.joined()
    }
}

/// Tests for what publishing writes for the person running the build.
@Suite("Publishing Output Tests")
struct PublishingOutputTests {
    /// Creates a context whose results are captured rather than shown.
    private func context(
        capturing captured: CapturedOutput,
        logOptions: PublishingLogOptions = .standard
    ) throws -> PublishingContext {
        try PublishingContext.initialize(
            for: TestSite(),
            from: #filePath,
            logOptions: logOptions,
            output: captured.output
        )
    }

    @Test("A line is written with a trailing newline")
    func lineAppendsNewline() {
        let captured = CapturedOutput()
        captured.output.line("first")
        captured.output.line()

        #expect(captured.writes == ["first\n", "\n"])
    }

    @Test("A build with a warning reports it under the exceptions heading")
    func warningIsWritten() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured)
        context.addWarning("Image has no alt text.")

        context.writeCompletionSummary()

        #expect(captured.writes == [
            "📘 Publish completed with exceptions:\n",
            "\t📙 Image has no alt text.\n"
        ])
    }

    @Test("A build with an error reports it under the exceptions heading")
    func errorIsWritten() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured)
        context.addError(.failedToWriteFile("robots.txt"))

        context.writeCompletionSummary()

        let description = try #require(PublishingError.failedToWriteFile("robots.txt").errorDescription)
        #expect(captured.writes == [
            "📘 Publish completed with exceptions:\n",
            "\t📕 \(description)\n"
        ])
    }

    @Test("Errors are reported before warnings, each group as one write")
    func errorsPrecedeWarnings() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured)
        context.addWarning("First warning.")
        context.addWarning("Second warning.")
        context.addError(.failedToParseMarkup)
        context.addError(.failedToWriteFeed)

        context.writeCompletionSummary()

        let parse = try #require(PublishingError.failedToParseMarkup.errorDescription)
        let feed = try #require(PublishingError.failedToWriteFeed.errorDescription)
        #expect(captured.writes == [
            "📘 Publish completed with exceptions:\n",
            "\t📕 \(parse)\n\t📕 \(feed)\n",
            "\t📙 First warning.\n\t📙 Second warning.\n"
        ])
    }

    @Test("A clean build reports completion")
    func cleanBuildReportsCompletion() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured)

        context.writeCompletionSummary()

        #expect(captured.writes == ["📗 Publish completed!\n"])
    }

    @Test("A clean build writes nothing when notices are off")
    func cleanBuildIsQuietWithoutNotices() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured, logOptions: [.warnings, .errors])

        context.writeCompletionSummary()

        #expect(captured.writes == [])
    }

    @Test("Silent log options write nothing even when there are warnings and errors")
    func silentWritesNothing() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured, logOptions: .silent)
        context.addWarning("Unseen warning.")
        context.addError(.failedToWriteFeed)

        context.writeCompletionSummary()

        #expect(captured.writes == [])
    }

    @Test("A build with only unreported warnings does not claim a clean completion")
    func unreportedWarningsSuppressCompletion() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured, logOptions: [.notices, .errors])
        context.addWarning("Unseen warning.")

        context.writeCompletionSummary()

        #expect(captured.writes == [])
    }

    @Test("Advice about a Span inside a Form goes to the context's output")
    func formAdviceIsWritten() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured)

        let html = PublishingContext.withCurrent(context) {
            Form { Span("Read-only") }.markupString()
        }

        #expect(html.contains("Read-only"))
        #expect(captured.writes == [
            "For proper alignment within Form, prefer a read-only, plain-text TextField over a Span.\n"
        ])
    }

    @Test("A resource that fails to decode is explained through the context's output")
    func undecodableResourceIsExplained() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-decode-\(UUID().uuidString)")
        let resources = root.appending(path: "Resources")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: root)
            } catch {
                Issue.record("Could not remove temporary resources: \(error)")
            }
        }
        try Data("not json".utf8).write(to: resources.appending(path: "broken.json"))

        let captured = CapturedOutput()
        let context = try context(capturing: captured)
        let decode = DecodeAction(sourceDirectory: root)

        let decoded: [String]? = PublishingContext.withCurrent(context) {
            decode("broken.json")
        }

        #expect(decoded == nil)
        #expect(captured.writes == ["Failed to decode broken.json because it appears to be invalid JSON.\n"])
    }

    @Test("A resource that cannot be located is reported through the context's output")
    func missingResourceIsWritten() throws {
        let captured = CapturedOutput()
        let context = try context(capturing: captured)
        let decode = DecodeAction(sourceDirectory: context.sourceDirectory)

        let decoded: [String]? = PublishingContext.withCurrent(context) {
            decode("no-such-file-\(UInt8.max).json")
        }

        #expect(decoded == nil)
        #expect(captured.writes == ["Failed to locate no-such-file-255.json in Resources folder.\n"])
    }

    @Test("A publish writes its results to the output it was given")
    func publishWritesToInjectedOutput() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ignite-output-\(UUID().uuidString)")
        let source = root.appending(path: "Source")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: root)
            } catch {
                Issue.record("Could not remove temporary site: \(error)")
            }
        }

        let captured = CapturedOutput()
        var site = OutputTestSite()
        try await site.publish(
            sourceDirectory: source,
            buildDirectory: root.appending(path: "Build"),
            logOptions: .standard,
            output: captured.output
        )

        #expect(captured.writes == [
            "Generating CSS for custom styles. This may take a moment...\n",
            "📘 Publish completed with exceptions:\n",
            "\t📙 Failed to find missing-include.html in Includes folder; it has been replaced with an empty string.\n"
        ])
    }
}

/// A one-page site whose only page asks for an include that does not exist.
private struct OutputTestSite: Site {
    var name = "Output Test"
    var url = URL(static: "https://www.example.com")
    var homePage = OutputTestHome()
    var layout = EmptyLayout()
    var feedConfiguration: FeedConfiguration? { nil }
}

/// A page that raises exactly one publishing warning.
private struct OutputTestHome: StaticPage {
    var title = "Home"

    var body: some HTML {
        Include("missing-include.html")
    }
}
