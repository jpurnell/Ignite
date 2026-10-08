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

    /// This HTML as the plain text a reader would see: its tags removed and its character
    /// references – named ones such as `&amp;` and `&copy;`, and numeric ones – decoded.
    ///
    /// Use it to take a title or a description out of rendered HTML. `strippingTags()`
    /// alone leaves the references in place, so the text of `Tom &amp; Jerry` would still
    /// read `Tom &amp; Jerry` and be escaped a second time wherever it was written.
    /// Tags are removed first, so a tag that was written as text (`&lt;b&gt;`) stays text.
    /// - Returns: The text of the HTML.
    func plainTextFromHTML() -> String {
        strippingTags().decodingHTMLCharacterReferences()
    }
}
