//
// URL-MarkupReference.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension URL {
    /// Parses an address that an author wrote into their site – a link target,
    /// an image path, a script or font file – so it can be written into a page.
    ///
    /// Ignite is a static site generator: these addresses end up as `href`, `src`
    /// and `url()` values for a visitor's browser to follow. Nothing in Ignite
    /// opens a connection to one, which is why no host allowlist applies here.
    /// Code that does need to load something from a URL must not use this
    /// initializer; it should validate the scheme and host it is about to contact.
    /// - Parameter string: The address as the author wrote it. It may be
    /// absolute (`https://example.com/a`) or relative (`/images/dog.jpg`).
    /// - Returns: `nil` when the string cannot be parsed as a URL at all.
    init?(markupReference string: String) {
        guard let url = URL(string: string) else { return nil }
        self = url
    }
}
