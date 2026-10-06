//
// Image.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `Image` element.
@Suite("Image Tests")
class ImageTests: IgniteTestSuite {
    @Test("Local Image", .publishingContext(), arguments: ["/images/example.jpg"], ["Example image"])
    func named(file: String, description: String) async throws {
        let element = Image(file, description: description)
        let output = element.markupString()

        // A root-relative path on a site with no subpath is emitted unchanged.
        #expect(output == "<img src=\"\(file)\" alt=\"\(description)\" />")
    }

    @Test("Remote Image", .publishingContext(), arguments: ["https://example.com"], ["Example image"])
    func named(url: String, description: String) async throws {
        let element = Image(url, description: description)
        let output = element.markupString()

        // A remote address is never rewritten.
        #expect(output == "<img src=\"\(url)\" alt=\"\(description)\" />")
    }

    @Test("Icon Image", .publishingContext(), arguments: ["browser-safari"], ["Safari logo"])
    func icon(systemName: String, description: String) async throws {
        let element = Image(systemName: systemName, description: description)
        let output = element.markupString()
        #expect(output == "<i class=\"bi-browser-safari\"></i>")
    }
}
