//
// Label.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// A form label with support for various styles
struct ControlLabel: InlineElement {
    /// The content and behavior of this HTML.
    var body: some InlineElement { self }

    /// The standard set of control attributes for HTML elements.
    var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    var isPrimitive: Bool { true }

    /// The text content of the label
    private let text: any InlineElement

    /// Creates a new control label with the specified text content.
    /// - Parameter text: The inline element to display within the label.
    init(_ text: any InlineElement) {
        self.text = text
    }

    /// The label as the text a reader would see, without its markup.
    var plainText: String {
        text.markupString().plainTextFromHTML().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the label has anything in it for a screen reader to announce.
    var namesItsControl: Bool {
        text.markupString().namesItsElement
    }

    func markup() -> Markup {
        let textHTML = text.markupString()
        return Markup("<label\(attributes)>\(textHTML)</label>")
    }
}
