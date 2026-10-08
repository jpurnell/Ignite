//
// String-JavaScriptStringLiteral.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

public extension String {
    /// This string written as a single-quoted JavaScript string literal, quotes included.
    ///
    /// Use it wherever a Swift string has to become a string in generated JavaScript –
    /// in an `Action`'s `compile()`, for example – and interpolate the result without
    /// adding quotes of your own:
    ///
    /// ```swift
    /// "document.getElementById(\(id.javaScriptStringLiteral())).focus()"
    /// ```
    ///
    /// Whatever the string contains, the result is one complete literal that evaluates
    /// back to that string, and it is safe both in an event attribute such as `onclick`
    /// and inside a `<script>` element:
    ///
    /// - A backslash, a single quote, and the line breaks JavaScript does not allow
    ///   inside a string (line feed, carriage return, U+2028 and U+2029) are escaped,
    ///   so the string cannot end early.
    /// - `"`, `&`, `<` and `>` are written as `\u0022`, `\u0026`, `\u003C` and `\u003E`,
    ///   so the literal cannot end an HTML attribute, form a character reference that
    ///   HTML would decode into a quote, or close a `<script>` element.
    /// - Other control characters are written as `\uXXXX`.
    ///
    /// - Returns: The JavaScript string literal for this string.
    func javaScriptStringLiteral() -> String {
        var literal = "'"

        for scalar in unicodeScalars {
            switch scalar {
            case "\\":
                literal += "\\\\"
            case "'":
                literal += "\\'"
            case "\n":
                literal += "\\n"
            case "\r":
                literal += "\\r"
            case "\t":
                literal += "\\t"
            case "\"", "&", "<", ">", "\u{2028}", "\u{2029}", "\u{7F}":
                literal += Self.javaScriptUnicodeEscape(for: scalar)
            case _ where scalar.value < 0x20:
                literal += Self.javaScriptUnicodeEscape(for: scalar)
            default:
                literal.unicodeScalars.append(scalar)
            }
        }

        return literal + "'"
    }

    /// The `\uXXXX` escape for a scalar in the Basic Multilingual Plane.
    private static func javaScriptUnicodeEscape(for scalar: Unicode.Scalar) -> String {
        let hex = String(scalar.value, radix: 16, uppercase: true)
        let padding = String(repeating: "0", count: Swift.max(0, 4 - hex.count))
        return "\\u" + padding + hex
    }
}
