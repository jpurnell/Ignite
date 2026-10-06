//
// PublishingLogger.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
#if canImport(os)
import os
#endif

#if canImport(os)
/// Ignite's diagnostics: what went wrong underneath a build, and where.
///
/// These are separate from a build's results, which go to ``PublishingOutput``.
/// Read them with `log stream --predicate 'subsystem == "org.roseclub.ignite"'`.
let logger = Logger(subsystem: "org.roseclub.ignite", category: "publishing")
#else
/// Ignite's diagnostics on platforms without the unified log, where they are discarded.
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
