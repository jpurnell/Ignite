//
// PublishingOutput.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// Writes the **results** of a publish for the person running the build.
///
/// A build's results are the things its author has to see when it finishes: the
/// warnings and errors collected along the way, and whether it completed. They are
/// written here rather than to a logger because they are what the build is *for* —
/// they must reach the terminal unprefixed and unfiltered, and `ignite build` relays
/// them from the site executable's standard output.
///
/// Everything else Ignite has to say — what failed underneath a warning, and why —
/// is a diagnostic, and goes to the unified log instead.
///
/// Passing your own output to `publish(…output:)` redirects those results, which is
/// also how tests read them back:
///
/// ```swift
/// try await site.publish(
///     from: #filePath,
///     buildDirectoryPath: "Build",
///     logOptions: .standard,
///     output: .standardError
/// )
/// ```
public struct PublishingOutput: Sendable {
    /// Receives each piece of text, already terminated with a newline.
    private let sink: @Sendable (String) -> Void

    /// Writes to the process's standard output. This is the default for a publish.
    public static let standard = PublishingOutput { text in
        FileHandle.standardOutput.write(Data(text.utf8))
    }

    /// Writes to the process's standard error.
    public static let standardError = PublishingOutput { text in
        FileHandle.standardError.write(Data(text.utf8))
    }

    /// Creates an output that forwards everything written to `sink`.
    /// - Parameter sink: Called once per write with the text to show,
    /// including its trailing newline.
    public init(sink: @escaping @Sendable (String) -> Void) {
        self.sink = sink
    }

    /// Writes one line.
    /// - Parameter text: The text to write, without a trailing newline.
    /// Defaults to an empty line.
    public func line(_ text: String = "") {
        sink(text + "\n")
    }
}
