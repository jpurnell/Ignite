//
//  CustomAction.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `CustomAction` action.
@Suite("CustomAction Tests")
class CustomActionTests: IgniteTestSuite {
    private nonisolated static let inputCode: [String] = [
        "example code",
        "special characters: \\@*_+-./",
        "double quotes: \"example\"",
        "single quotes: 'example'",
        """
        multiline string
        with double quotes "example"
        and single quotes 'example'
        """
    ]

    /// What each piece of code looks like as the value of a double-quoted event attribute:
    /// the code as written, with each double quote as `&quot;` so it cannot end the attribute.
    private nonisolated static let attributeValues: [String] = [
        "example code",
        "special characters: \\@*_+-./",
        "double quotes: &quot;example&quot;",
        "single quotes: 'example'",
        "multiline string\nwith double quotes &quot;example&quot;\nand single quotes 'example'"
    ]

    @Test("Test initializer", .publishingContext(), arguments: zip(inputCode, inputCode))
    func initializer(input: String, output: String) async throws {
        let action = CustomAction(input)
        #expect(action.code == output)
    }

    @Test("Verify compile action returns the code as written", .publishingContext(), arguments: zip(inputCode, inputCode))
    func compile(input: String, output: String) async throws {
        let action = CustomAction(input)
        #expect(action.compile() == output)
    }

    @Test("Verify the code is escaped for its event attribute", .publishingContext(),
          arguments: zip(inputCode, attributeValues))
    func attributeValue(input: String, output: String) async throws {
        let element = Tag("div") {}.onClick { CustomAction(input) }
        #expect(element.markupString() == "<div onclick=\"\(output)\"></div>")
    }
}
