//
// String-StrippingTags.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension String {
    /// Removes all HTML tags from a string, so it's safe to use as plain-text.
    func strippingTags() -> String {
        self.replacing(#/<.*?>/#, with: "")
    }

    /// This HTML as the plain text a reader would see: its tags removed and the character
    /// references `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&apos;` and numeric ones decoded.
    ///
    /// Use it to take a title or a description out of rendered HTML. `strippingTags()`
    /// alone leaves the references in place, so the text of `Tom &amp; Jerry` would still
    /// read `Tom &amp; Jerry` and be escaped a second time wherever it was written.
    /// Other named references, such as `&copy;`, are left as they are.
    /// - Returns: The text of the HTML.
    func plainTextFromHTML() -> String {
        strippingTags().replacing(#/&(?:(amp|lt|gt|quot|apos)|#([0-9]{1,7})|#[xX]([0-9A-Fa-f]{1,6}));/#) { match in
            if let name = match.output.1 {
                return switch name {
                case "amp": "&"
                case "lt": "<"
                case "gt": ">"
                case "quot": "\""
                default: "'"
                }
            }

            let code = match.output.2.flatMap { UInt32($0) } ?? match.output.3.flatMap { UInt32($0, radix: 16) }
            guard let code, let scalar = Unicode.Scalar(code) else { return String(match.output.0) }
            return String(Character(scalar))
        }
    }
}
