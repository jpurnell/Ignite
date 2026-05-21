//
//  ValidationSeverity.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// How serious a validation finding is.
public enum ValidationSeverity: Sendable, Comparable {
    case info
    case warning
    case error
}
