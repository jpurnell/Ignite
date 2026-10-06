//
// Output.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
#if canImport(os)
import os
#endif

/// Writes what a command has to tell the person who ran it.
///
/// Deliberately neither a console-printing call nor a `Logger`. What `ignite` writes
/// is its product: it is read, piped and redirected by whoever ran it, so it must not
/// be prefixed, filtered or subject to log levels. Results go to ``standard``;
/// messages explaining why a command could not do its job go to ``standardError``,
/// so that redirecting a command's results does not swallow the reason it failed.
/// Diagnostics go to `logger` instead, where they are queryable.
///
/// Each command takes its outputs as parameters, which is also the seam for
/// asserting on what a command says without capturing file descriptors.
struct Output: Sendable {
    /// Receives each piece of text, already terminated with a newline.
    private let sink: @Sendable (String) -> Void

    /// Writes to the process's standard output.
    static let standard = Output { text in
        FileHandle.standardOutput.write(Data(text.utf8))
    }

    /// Writes to the process's standard error.
    static let standardError = Output { text in
        FileHandle.standardError.write(Data(text.utf8))
    }

    /// Creates an output that forwards everything written to `sink`.
    init(sink: @escaping @Sendable (String) -> Void) {
        self.sink = sink
    }

    /// Writes one line.
    func line(_ text: String = "") {
        sink(text + "\n")
    }
}

#if canImport(os)
/// The tool's diagnostics — queryable, filterable, and separate from its results.
///
/// Read them with `log stream --predicate 'subsystem == "org.roseclub.ignite"'`.
let logger = Logger(subsystem: "org.roseclub.ignite", category: "cli")
#else
/// The tool's diagnostics on platforms without the unified log, where they are discarded.
let logger = DiagnosticLogger()

/// Stands in for `os.Logger` where `os` is unavailable.
///
/// It accepts the same calls, privacy annotations included, so call sites are
/// written once; nothing is evaluated or written.
struct DiagnosticLogger: Sendable {
    /// Discards a debug-level message.
    func debug(_ message: DiagnosticMessage) {}

    /// Discards an info-level message.
    func info(_ message: DiagnosticMessage) {}

    /// Discards a notice-level message.
    func notice(_ message: DiagnosticMessage) {}

    /// Discards a warning-level message.
    func warning(_ message: DiagnosticMessage) {}

    /// Discards an error-level message.
    func error(_ message: DiagnosticMessage) {}

    /// Discards a fault-level message.
    func fault(_ message: DiagnosticMessage) {}
}

/// A log message that parses like `OSLogMessage` and keeps nothing.
struct DiagnosticMessage: ExpressibleByStringInterpolation, Sendable {
    /// Mirrors the privacy levels call sites pass to `os.Logger`.
    enum Privacy: Sendable {
        case auto, `public`, `private`, sensitive
    }

    /// Accepts literal and interpolated segments without storing them.
    struct StringInterpolation: StringInterpolationProtocol {
        init(literalCapacity: Int, interpolationCount: Int) {}

        mutating func appendLiteral(_ literal: String) {}

        mutating func appendInterpolation<Value>(
            _ value: @autoclosure () -> Value,
            privacy: Privacy = .auto
        ) {}
    }

    init(stringLiteral value: String) {}

    init(stringInterpolation: StringInterpolation) {}
}
#endif
