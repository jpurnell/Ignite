//
// String-CSSStringLiteral.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

extension String {
    /// This string written as a single-quoted CSS string, quotes included.
    ///
    /// Use it wherever a name or an address becomes a string in CSS – a font family, the
    /// argument of `url()` – and interpolate the result without adding quotes of your own.
    /// A backslash and a single quote are escaped, and a line break, which CSS does not
    /// allow inside a string, is written as its hexadecimal escape, so nothing in the
    /// value can end the string and continue as CSS of its own.
    /// - Returns: The CSS string for this value. A value containing none of those
    /// characters is returned unchanged between quotes.
    func cssStringLiteral() -> String {
        var literal = "'"

        for scalar in unicodeScalars {
            switch scalar {
            case "\\":
                literal += "\\\\"
            case "'":
                literal += "\\'"
            case "\n":
                literal += "\\a "
            case "\r":
                literal += "\\d "
            case "\u{C}":
                literal += "\\c "
            default:
                literal.unicodeScalars.append(scalar)
            }
        }

        return literal + "'"
    }
}
