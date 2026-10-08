//
// String-EscapedForJavaScript.swift
// IgniteSamples
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

public extension String {
    /// Escapes single quotes for a JavaScript string and double quotes for an HTML attribute.
    ///
    /// Prefer `javaScriptStringLiteral()`, which returns a complete, quoted JavaScript
    /// string literal that no input can break out of. This method does two jobs partially:
    /// it leaves backslashes and line breaks alone, so a string can still end a JavaScript
    /// string literal early, and it writes an HTML character reference into text that may
    /// not be HTML. Ignite no longer calls it; it is kept, unchanged, for code that does.
    /// - Returns: The string with `'` written as `\'` and `"` written as `&quot;`.
    func escapedForJavascript() -> String {
        self
            .replacing("'", with: "\\'")
            .replacing("\"", with: "&quot;")
    }
}
