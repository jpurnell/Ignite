//
// Attribute.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A simple key-value pair of strings that is able to store custom attributes.
struct Attribute: Hashable, Equatable, Sendable, Comparable, CustomStringConvertible {
    /// The attribute's name, e.g. "target" or "rel".
    var name: String

    /// The attribute's value, e.g. "myFrame" or "stylesheet".
    var value: String?

    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    init(_ name: String) {
        self.name = name
        self.value = nil
    }

    /// The attribute as it is written in HTML: `name="value"`, or just the name when there is no value.
    ///
    /// The value is escaped for a double-quoted attribute, so nothing in it can end the
    /// attribute or be read as markup. The name is reduced to the characters HTML allows
    /// in an attribute name, since a name cannot be escaped.
    public var description: String {
        let name = Self.markupName(name)

        return if let value {
            "\(name)=\"\(value.escapedForHTML())\""
        } else {
            name
        }
    }

    /// A name with the characters HTML does not allow in an attribute name removed.
    ///
    /// Those are whitespace, control characters, `"`, `'`, `<`, `>`, `/` and `=`: each of
    /// them ends the name, so leaving one in would turn the rest of the name into further
    /// attributes or into markup.
    /// - Parameter name: The attribute name as it was given.
    /// - Returns: The name, containing only characters that can be part of one.
    static func markupName(_ name: String) -> String {
        let scalars = name.unicodeScalars.filter { scalar in
            switch scalar {
            case "\"", "'", "<", ">", "/", "=":
                false
            default:
                scalar.properties.isWhitespace == false && scalar.properties.generalCategory != .control
            }
        }

        return String(String.UnicodeScalarView(scalars))
    }

    /// Orders attributes alphabetically by the way they are written in HTML.
    public static func < (lhs: Attribute, rhs: Attribute) -> Bool {
        lhs.description < rhs.description
    }
}
