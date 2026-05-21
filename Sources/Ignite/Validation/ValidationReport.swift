//
//  ValidationReport.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// The complete result of running all validators against a site.
public struct ValidationReport: Sendable {
    public let findings: [ValidationRule]

    public var hasErrors: Bool {
        findings.contains { $0.severity == .error }
    }

    public var hasWarnings: Bool {
        findings.contains { $0.severity >= .warning }
    }

    public func findings(severity: ValidationSeverity) -> [ValidationRule] {
        findings.filter { $0.severity == severity }
    }

    public enum OutputStyle: Sendable {
        case terminal
        case xcode
    }

    public func formatted(style: OutputStyle = .terminal) -> String {
        guard !findings.isEmpty else { return "No validation issues found." }

        switch style {
        case .terminal:
            return findings.map { finding in
                let label = switch finding.severity {
                case .info: "info"
                case .warning: "warning"
                case .error: "error"
                }
                let source = finding.source.map { " [\($0)]" } ?? ""
                return "[\(label)]\(source) \(finding.message)"
            }.joined(separator: "\n")

        case .xcode:
            return findings.map { finding in
                let label = switch finding.severity {
                case .info: "note"
                case .warning: "warning"
                case .error: "error"
                }
                let source = finding.source ?? "<unknown>"
                return "\(source): \(label): \(finding.message) (\(finding.validatorName))"
            }.joined(separator: "\n")
        }
    }
}
