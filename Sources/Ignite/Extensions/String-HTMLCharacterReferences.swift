//
// String-HTMLCharacterReferences.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

extension String {
    /// Replaces the HTML character references in this string with the characters they
    /// stand for, as the HTML Standard's tokenizer does for text.
    ///
    /// - Named references are the standard's full set – `&copy;`, `&eacute;`, `&nbsp;`
    ///   and the two thousand others. A name must end in a semicolon unless it is one of
    ///   the hundred or so the standard also accepts without (`&amp`, `&copy`), and
    ///   where two names match, the longer one is used.
    /// - Numeric references are decimal (`&#169;`) or hexadecimal (`&#xA9;`), and reach
    ///   every code point, including those beyond the Basic Multilingual Plane.
    ///   A reference to zero, to a surrogate or to a number beyond U+10FFFF becomes
    ///   U+FFFD, the replacement character, and one in the range 0x80–0x9F is read as
    ///   Windows-1252, as browsers read it.
    /// - Anything else beginning with `&` is not a reference and is left as written.
    ///
    /// Each reference is decoded once: `&amp;copy;` is the text `&copy;`.
    /// - Returns: The string with its character references decoded.
    func decodingHTMLCharacterReferences() -> String {
        guard contains("&") else { return self }

        let scalars = Array(unicodeScalars)
        var output = String.UnicodeScalarView()
        var index = scalars.startIndex

        while index < scalars.endIndex {
            if scalars[index] == "&", let reference = HTMLCharacterReference(in: scalars, at: index) {
                output.append(contentsOf: reference.replacement)
                index += reference.length
            } else {
                output.append(scalars[index])
                index += 1
            }
        }

        return String(output)
    }
}

/// One character reference found in a run of text.
private struct HTMLCharacterReference {
    /// The code points the reference stands for.
    var replacement: [Unicode.Scalar]

    /// How many code points of the text the reference occupies, counting its `&`.
    var length: Int

    /// Reads the character reference that begins at an ampersand.
    /// - Parameters:
    ///   - scalars: The text.
    ///   - ampersand: The position of an `&` in it.
    /// - Returns: `nil` when what follows the ampersand is not a character reference.
    init?(in scalars: [Unicode.Scalar], at ampersand: Int) {
        let start = ampersand + 1
        guard start < scalars.endIndex else { return nil }

        if scalars[start] == "#" {
            self.init(numericIn: scalars, at: ampersand)
        } else {
            self.init(namedIn: scalars, at: ampersand)
        }
    }

    // MARK: - Named references

    /// Reads a named reference, taking the longest name in the standard's table that the
    /// text begins with.
    private init?(namedIn scalars: [Unicode.Scalar], at ampersand: Int) {
        // Every name is ASCII letters and digits, with a semicolon at most at its end.
        var name = ""
        var end = ampersand + 1
        while end < scalars.endIndex, name.count < HTMLNamedCharacterReferences.longestNameLength,
              Self.isNameCharacter(scalars[end]) {
            name.unicodeScalars.append(scalars[end])
            end += 1
        }

        guard name.isEmpty == false else { return nil }

        if end < scalars.endIndex, scalars[end] == ";", let replacement = Self.table["\(name);"] {
            self.replacement = replacement
            self.length = end + 1 - ampersand
            return
        }

        // Without its semicolon only one of the legacy names can match, and it may be
        // followed directly by more text: `&notit;` is `&not` and then `it;`.
        var prefix = Substring(name.prefix(HTMLNamedCharacterReferences.longestLegacyNameLength))
        while prefix.isEmpty == false {
            if let replacement = Self.table[String(prefix)] {
                self.replacement = replacement
                self.length = prefix.count + 1
                return
            }
            prefix = prefix.dropLast()
        }

        return nil
    }

    private static func isNameCharacter(_ scalar: Unicode.Scalar) -> Bool {
        ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar) || ("0"..."9").contains(scalar)
    }

    /// The standard's table, keyed by name as it follows the ampersand.
    private static let table: [String: [Unicode.Scalar]] = {
        var table = [String: [Unicode.Scalar]](minimumCapacity: HTMLNamedCharacterReferences.count)

        for line in HTMLNamedCharacterReferences.source.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=")
            guard parts.count == 2 else { continue }
            let scalars = parts[1].split(separator: ",").compactMap { UInt32($0, radix: 16).flatMap(Unicode.Scalar.init) }
            table[String(parts[0])] = scalars
        }

        return table
    }()

    /// The number of names read from the generated table.
    static var tableCount: Int { table.count }

    // MARK: - Numeric references

    /// Reads a numeric reference: `&#` and decimal digits, or `&#x` and hexadecimal
    /// digits, with the semicolon the standard expects but does not require.
    private init?(numericIn scalars: [Unicode.Scalar], at ampersand: Int) {
        var end = ampersand + 2
        var radix: UInt32 = 10

        if end < scalars.endIndex, scalars[end] == "x" || scalars[end] == "X" {
            radix = 16
            end += 1
        }

        let firstDigit = end
        var value: UInt32 = 0

        while end < scalars.endIndex, let digit = Self.digit(scalars[end], radix: radix) {
            // Past the last code point the number can only be out of range, so it is
            // held there rather than left to overflow.
            value = min(value * radix + digit, Self.beyondUnicode)
            end += 1
        }

        guard end > firstDigit else { return nil }

        if end < scalars.endIndex, scalars[end] == ";" {
            end += 1
        }

        self.replacement = [Self.scalar(forNumber: value)]
        self.length = end - ampersand
    }

    /// A number greater than any code point.
    private static let beyondUnicode: UInt32 = 0x110000

    private static func digit(_ scalar: Unicode.Scalar, radix: UInt32) -> UInt32? {
        let value: UInt32
        switch scalar {
        case "0"..."9": value = scalar.value - 0x30
        case "a"..."f": value = scalar.value - 0x61 + 10
        case "A"..."F": value = scalar.value - 0x41 + 10
        default: return nil
        }
        return value < radix ? value : nil
    }

    /// The character a numeric reference stands for, by the standard's rules for numbers
    /// that are not characters.
    private static func scalar(forNumber value: UInt32) -> Unicode.Scalar {
        let replacementCharacter: Unicode.Scalar = "\u{FFFD}"

        // Zero, a number beyond Unicode and a surrogate – for which `Unicode.Scalar`
        // has no value – are not characters at all.
        guard value != 0, let scalar = Unicode.Scalar(value) else { return replacementCharacter }

        // 0x80–0x9F are control codes in Unicode, but pages written in Windows-1252 used
        // these numbers for its punctuation, and the standard keeps reading them so.
        return windows1252[value] ?? scalar
    }

    /// The characters Windows-1252 has where Unicode has the C1 control codes.
    private static let windows1252: [UInt32: Unicode.Scalar] = [
        0x80: "\u{20AC}", 0x82: "\u{201A}", 0x83: "\u{0192}", 0x84: "\u{201E}", 0x85: "\u{2026}",
        0x86: "\u{2020}", 0x87: "\u{2021}", 0x88: "\u{02C6}", 0x89: "\u{2030}", 0x8A: "\u{0160}",
        0x8B: "\u{2039}", 0x8C: "\u{0152}", 0x8E: "\u{017D}", 0x91: "\u{2018}", 0x92: "\u{2019}",
        0x93: "\u{201C}", 0x94: "\u{201D}", 0x95: "\u{2022}", 0x96: "\u{2013}", 0x97: "\u{2014}",
        0x98: "\u{02DC}", 0x99: "\u{2122}", 0x9A: "\u{0161}", 0x9B: "\u{203A}", 0x9C: "\u{0153}",
        0x9E: "\u{017E}", 0x9F: "\u{0178}"
    ]
}

extension HTMLNamedCharacterReferences {
    /// The number of names the decoder read from ``source``. It equals ``count`` when
    /// every line of the table was understood.
    static var parsedCount: Int { HTMLCharacterReference.tableCount }
}
