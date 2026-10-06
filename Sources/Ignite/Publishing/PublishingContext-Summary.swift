//
// PublishingContext-Summary.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension PublishingContext {
    /// Writes the outcome of a publish to ``output``: every collected error and
    /// warning the log options allow, or a completion notice when there were none.
    ///
    /// The same outcome is recorded in the unified log whatever the log options
    /// say, so a build run quietly can still be examined afterwards.
    func writeCompletionSummary() {
        let errorMessages = shouldLog(.errors) ? errors.compactMap(\.errorDescription) : []
        let warningMessages = shouldLog(.warnings) ? Array(warnings) : []

        for error in errors {
            let description = error.errorDescription ?? String(describing: error)
            logger.error("Publishing error: \(description, privacy: .public)")
        }
        for warning in warnings {
            logger.warning("Publishing warning: \(warning, privacy: .public)")
        }
        let counts = "\(errors.count) error(s), \(warnings.count) warning(s)"
        logger.info("Publish finished: \(counts, privacy: .public).")

        if !errorMessages.isEmpty || !warningMessages.isEmpty {
            output.line("📘 Publish completed with exceptions:")
            if !errorMessages.isEmpty {
                output.line(errorMessages.map { "\t📕 \($0)" }.joined(separator: "\n"))
            }
            if !warningMessages.isEmpty {
                output.line(warningMessages.map { "\t📙 \($0)" }.joined(separator: "\n"))
            }
        } else if errors.isEmpty && warnings.isEmpty && shouldLog(.notices) {
            output.line("📗 Publish completed!")
        }
    }
}
