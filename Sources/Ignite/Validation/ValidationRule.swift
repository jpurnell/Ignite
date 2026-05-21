//
//  ValidationRule.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// A single validation finding.
public struct ValidationRule: Sendable {
    public let severity: ValidationSeverity
    public let message: String
    public let source: String?
    public let target: String?
    public let validatorName: String
}
