//
// String-EscapedForHTML.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

public extension String {
    /// This string written so that HTML reads it back as the same text.
    ///
    /// `&`, `<`, `>` and `"` are written as `&amp;`, `&lt;`, `&gt;` and `&quot;`. The result
    /// is safe as the text of an element and as the value of a double-quoted attribute.
    ///
    /// Ignite does this for you wherever it writes an attribute, a page title or metadata.
    /// It does not do it to a string you use as an element – `Text("…")`, `Span("…")`, a
    /// string in a builder – because such a string is HTML and may contain tags and
    /// character references of your own. When the string is text that you do not control,
    /// such as a value read from a file, escape it first:
    ///
    /// ```swift
    /// Text(product.name.escapedForHTML())
    /// ```
    ///
    /// A character reference already in the string is text like any other, so `&amp;`
    /// becomes `&amp;amp;`: escape a string once. A single quote is left as it is, since
    /// Ignite writes every attribute in double quotes; do not use the result inside a
    /// single-quoted attribute of your own.
    /// - Returns: The string with the characters HTML treats as markup escaped.
    func escapedForHTML() -> String {
        var escaped = ""
        escaped.reserveCapacity(utf8.count)

        for character in self {
            switch character {
            case "&": escaped += "&amp;"
            case "<": escaped += "&lt;"
            case ">": escaped += "&gt;"
            case "\"": escaped += "&quot;"
            default: escaped.append(character)
            }
        }

        return escaped
    }
}

extension String {
    /// This string written as the text of a code element, leaving alone any character
    /// reference it already contains.
    ///
    /// `<` and `>` become `&lt;` and `&gt;`, so `Array<Int>` is shown rather than read
    /// as a tag. `&` becomes `&amp;` unless it begins a character reference such as
    /// `&lt;`, `&#60;` or `&#x3C;`: Ignite's code elements have always asked for angle
    /// brackets to be written that way, and code that does so must keep rendering as it
    /// did. The cost is that a reference cannot be shown literally by writing it once –
    /// to show `&lt;`, write `&amp;lt;`, as before.
    /// - Returns: The string with markup characters escaped and character references kept.
    func escapedForHTMLKeepingCharacterReferences() -> String {
        var escaped = ""
        escaped.reserveCapacity(utf8.count)
        var remainder = self[...]

        while let character = remainder.first {
            switch character {
            case "<":
                escaped += "&lt;"
            case ">":
                escaped += "&gt;"
            case "&":
                escaped += Self.beginsCharacterReference(remainder) ? "&" : "&amp;"
            default:
                escaped.append(character)
            }

            remainder = remainder.dropFirst()
        }

        return escaped
    }

    /// Whether text beginning with `&` begins a character reference: `&name;`, `&#60;` or `&#x3C;`.
    /// - Parameter text: The text to examine, starting at an ampersand.
    /// - Returns: `true` if the ampersand opens a complete character reference.
    private static func beginsCharacterReference(_ text: Substring) -> Bool {
        guard let end = text.firstIndex(of: ";") else { return false }
        let name = text[text.index(after: text.startIndex)..<end]
        guard let first = name.unicodeScalars.first else { return false }

        if first == "#" {
            let digits = name.unicodeScalars.dropFirst()
            if let marker = digits.first, marker == "x" || marker == "X" {
                let hexDigits = digits.dropFirst()
                return hexDigits.isEmpty == false && hexDigits.allSatisfy(\.properties.isASCIIHexDigit)
            }
            return digits.isEmpty == false && digits.allSatisfy { ("0"..."9").contains($0) }
        }

        return isASCIILetter(first) && name.unicodeScalars.allSatisfy { isASCIILetter($0) || ("0"..."9").contains($0) }
    }

    /// Whether a scalar is one of the letters A–Z or a–z.
    private static func isASCIILetter(_ scalar: Unicode.Scalar) -> Bool {
        ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar)
    }
}
