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
        #expect(output == "<i role=\"img\" class=\"bi-browser-safari\" aria-label=\"Safari logo\"></i>")
    }

    @Test("Image variants are matched by name without regard to case", arguments: [
        ("photo@2x", "photo", Image.Variant.light),
        ("photo~light", "Photo", .light),
        ("PHOTO~DARK", "photo", .dark),
        ("photo@2x~dark", "photo", .dark),
        // `I` and `i` are the letters a Turkish locale does not consider the same;
        // a file name must match the same way wherever the site is built.
        ("ICON@2x", "icon", .light),
        ("icon~dark", "ICON", .dark)
    ])
    func variantMatching(filename: String, imageName: String, expected: Image.Variant) {
        #expect(Image.variant(ofFileNamed: filename, forImageNamed: imageName) == expected)
    }

    @Test("Files that are not variants of an image are not matched", arguments: [
        ("photo", "photo"), ("other@2x", "photo"), ("photograph@2x", "photo"), ("ıcon@2x", "icon"), ("İcon@2x", "icon")
    ])
    func nonVariants(filename: String, imageName: String) {
        #expect(Image.variant(ofFileNamed: filename, forImageNamed: imageName) == nil)
    }
}
