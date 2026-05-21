//
//  ValidationReportTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for core validation types.
@Suite("ValidationReport Tests")
struct ValidationReportTests {

    // MARK: - ValidationSeverity

    @Test("Severity is ordered info < warning < error")
    func severityOrdering() {
        #expect(ValidationSeverity.info < .warning)
        #expect(ValidationSeverity.warning < .error)
        #expect(ValidationSeverity.info < .error)
    }

    // MARK: - ValidationRule

    @Test("ValidationRule stores all fields")
    func ruleFields() {
        let rule = ValidationRule(
            severity: .error,
            message: "Missing title",
            source: "/blog/test",
            target: nil,
            validatorName: "TestValidator"
        )

        #expect(rule.severity == .error)
        #expect(rule.message == "Missing title")
        #expect(rule.source == "/blog/test")
        #expect(rule.target == nil)
        #expect(rule.validatorName == "TestValidator")
    }

    // MARK: - ValidationReport

    @Test("Empty report has no errors or warnings")
    func emptyReport() {
        let report = ValidationReport(findings: [])
        #expect(!report.hasErrors)
        #expect(!report.hasWarnings)
        #expect(report.findings.isEmpty)
    }

    @Test("Report detects errors")
    func reportHasErrors() {
        let findings = [
            ValidationRule(severity: .error, message: "broken", source: nil, target: nil, validatorName: "test")
        ]
        let report = ValidationReport(findings: findings)
        #expect(report.hasErrors)
        #expect(report.hasWarnings)
    }

    @Test("Report detects warnings without errors")
    func reportHasWarningsOnly() {
        let findings = [
            ValidationRule(severity: .warning, message: "missing image", source: nil, target: nil, validatorName: "test")
        ]
        let report = ValidationReport(findings: findings)
        #expect(!report.hasErrors)
        #expect(report.hasWarnings)
    }

    @Test("Findings can be filtered by severity")
    func filterBySeverity() {
        let findings = [
            ValidationRule(severity: .error, message: "e1", source: nil, target: nil, validatorName: "t"),
            ValidationRule(severity: .warning, message: "w1", source: nil, target: nil, validatorName: "t"),
            ValidationRule(severity: .info, message: "i1", source: nil, target: nil, validatorName: "t"),
            ValidationRule(severity: .error, message: "e2", source: nil, target: nil, validatorName: "t")
        ]
        let report = ValidationReport(findings: findings)

        #expect(report.findings(severity: .error).count == 2)
        #expect(report.findings(severity: .warning).count == 1)
        #expect(report.findings(severity: .info).count == 1)
    }

    @Test("Formatted output includes finding messages")
    func formattedOutput() {
        let findings = [
            ValidationRule(severity: .error, message: "Missing title", source: "/test", target: nil, validatorName: "TestValidator")
        ]
        let report = ValidationReport(findings: findings)
        let output = report.formatted(style: .terminal)

        #expect(output.contains("Missing title"))
        #expect(output.contains("error"))
    }

    @Test("Xcode format includes file path")
    func xcodeFormat() {
        let findings = [
            ValidationRule(severity: .warning, message: "No image", source: "/blog/post", target: nil, validatorName: "TestValidator")
        ]
        let report = ValidationReport(findings: findings)
        let output = report.formatted(style: .xcode)

        #expect(output.contains("/blog/post"))
        #expect(output.contains("warning"))
        #expect(output.contains("No image"))
    }

    // MARK: - ValidationMode

    @Test("All validation modes exist")
    func validationModes() {
        let modes: [ValidationMode] = [.disabled, .warn, .strict]
        #expect(modes.count == 3)
    }
}
