//
// RawTextElement.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// The two HTML elements whose content is read as it is written: `<style>` and `<script>`.
///
/// Character references are not decoded inside them, so their content cannot be escaped
/// the way text and attribute values are. A browser simply reads up to the first closing
/// tag – `</style` or `</script`, in any case – wherever that is: inside a CSS string, a
/// JavaScript string, a comment. This is the one place that writes those elements, and it
/// rewrites the few sequences HTML would act on into forms CSS and JavaScript read as the
/// same characters.
enum RawTextElement: String, Sendable {
    /// A `<style>` element, holding CSS.
    case style

    /// A `<script>` element, holding JavaScript.
    case script

    /// Writes the element with its content made safe to stand inside it.
    /// - Parameters:
    ///   - attributes: The element's attributes.
    ///   - content: The CSS or JavaScript to put in the element.
    /// - Returns: The markup of the whole element.
    func markup(attributes: CoreAttributes = CoreAttributes(), content: String) -> Markup {
        Markup("<\(rawValue)\(attributes)>\(neutralizing(content))</\(rawValue)>")
    }

    /// Rewrites content so that nothing in it ends the element or keeps it open.
    ///
    /// - In CSS, `</style` is written `<\/style`. A backslash before a character that is
    ///   not a hexadecimal digit or a line break stands for that character, in a string,
    ///   a `url()` or an identifier alike.
    /// - In JavaScript, `</script` is written `<\/script`, which is the same text in a
    ///   string, a template or a regular expression.
    /// - In JavaScript, `<script` is written `\x3Cscript` where it follows an unclosed
    ///   `<!--`. HTML reads that pair as a script inside a comment, and then takes the
    ///   element's real closing tag for the inner script's, leaving the element open to
    ///   the end of the page. An opening tag anywhere else is harmless and is left alone,
    ///   as is `<!--` itself, which JavaScript reads as the start of a comment.
    ///
    /// Content with none of these sequences is returned exactly as it was given.
    /// - Parameter content: The CSS or JavaScript as it was given.
    /// - Returns: Content that means the same to CSS or JavaScript.
    func neutralizing(_ content: String) -> String {
        switch self {
        case .style:
            content.replacing(#/<\/(?=style)/#.ignoresCase(), with: #"<\/"#)
        case .script:
            Self.escapingScriptOpenersInComments(
                in: content.replacing(#/<\/(?=script)/#.ignoresCase(), with: #"<\/"#))
        }
    }

    /// Escapes each `<script` that follows a `<!--` with no `-->` between them.
    ///
    /// This follows the HTML tokenizer's script data states: `<!--` begins an escaped
    /// section, `-->` ends it, and inside it `<script` followed by white space, `/` or
    /// `>` begins a nested script.
    private static func escapingScriptOpenersInComments(in code: String) -> String {
        var output = ""
        var rest = Substring(code)

        while let opener = rest.range(of: "<!--") {
            output += rest[..<opener.upperBound]

            // The dashes that open the section can also be the ones that close it: `<!-->`.
            var section = rest[rest.index(opener.lowerBound, offsetBy: 2)...]
            var written = opener.upperBound
            var isClosed = false

            while isClosed == false,
                  let match = section.firstMatch(of: #/-->|<(?=script[\t\n\f\r \/>])/#.ignoresCase()) {
                if match.range.lowerBound > written {
                    output += rest[written..<match.range.lowerBound]
                }

                if match.output.first == "<" {
                    output += #"\x3C"#
                } else {
                    // Part of the closer may already have been written with the opener.
                    output += rest[max(written, match.range.lowerBound)..<match.range.upperBound]
                    isClosed = true
                }

                written = max(written, match.range.upperBound)
                section = rest[match.range.upperBound...]
            }

            rest = rest[written...]
            if isClosed == false { break }
        }

        return output + rest
    }
}
