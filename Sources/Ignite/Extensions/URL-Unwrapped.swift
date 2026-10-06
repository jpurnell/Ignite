//
// URL-Unwrapped.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension URL {
    /// A placeholder for metadata whose real URL has not been supplied yet.
    ///
    /// This is `about:blank`. Foundation offers no non-failable way to build a URL
    /// from a string, so the parse result is unwrapped with the file-system root as
    /// a stand-in that still reads as "nowhere in particular".
    static let blankPlaceholder = URL(string: "about:blank") ?? URL(filePath: "/")
}

public extension URL {
    /// Creates URLs from static strings, which will only fail if you have made
    /// a significant typing error.
    /// - Note: A string that cannot be parsed as a URL produces `about:blank`
    /// rather than stopping the build, and adds a warning to the current build
    /// naming the string.
    init(static string: StaticString) {
        let literal = String(describing: string)

        if let created = URL(markupReference: literal) {
            self = created
        } else {
            PublishingContext.current?.addWarning("""
            A URL was created from a string that is not a valid URL: '\(literal)'. \
            It was replaced with about:blank.
            """)
            self = .blankPlaceholder
        }
    }
}
