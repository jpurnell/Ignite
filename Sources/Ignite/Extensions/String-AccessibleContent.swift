//
// String-AccessibleContent.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension String {
    /// Whether this markup, as the content of an element, gives that element a name for
    /// assistive technology.
    ///
    /// Content names its element when it has text, or holds something that carries a name
    /// of its own: an image with `alt` text, or an element with an `aria-label`,
    /// `aria-labelledby` or `title`. An icon alone – an empty `<i>` or `<span>` – does not.
    var namesItsElement: Bool {
        let text = plainTextFromHTML().trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty else { return true }
        return contains(#/\s(?:alt|aria-label|aria-labelledby|title)="[^"]+"/#)
    }
}
