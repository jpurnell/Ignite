//
// CodeBlock.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// An separated section of programming code. For inline code that sit along other
/// text on your page, use `Code` instead.
///
/// - Note: Write the code as it is. Angle brackets and ampersands – `Array<Int>`,
/// `a && b` – are escaped for you, so they are shown rather than read as HTML. A
/// character reference such as `&lt;` is left as it is and shows the character it names,
/// because earlier versions asked for angle brackets to be written that way; to show a
/// reference itself, write its ampersand as `&amp;`.
public struct CodeBlock: HTML {
    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The code to display.
    var content: String

    /// The language of the code being shown.
    var language: HighlighterLanguage?

    /// Creates a new `Code` instance from the given content.
    /// - Parameters:
    ///   - language: The programming language for the code. This affects
    ///   how the content is tagged, which in turn affects syntax highlighting.
    ///   - content: The code you want to render.
    public init(_ language: HighlighterLanguage? = nil, _ content: () -> String) {
        self.language = language
        self.content = content()
    }

    /// A code block with highlighted lines.
    /// - Parameter lines: Individual line numbers to highlight.
    /// - Returns: A copy of this code block with the specified lines highlighted.
    public func highlightedLines(_ lines: Int...) -> Self {
        var copy = self
        let highlights = lines.map { "\($0)" }
        let dataLine = highlights.joined(separator: ",")
        copy.attributes.append(dataAttributes: .init(name: "line", value: dataLine))
        return copy
    }

    /// A code block with highlighted line ranges.
    /// - Parameter ranges: Ranges of lines to highlight.
    /// - Returns: A copy of this code block with the specified line ranges highlighted.
    public func highlightedRanges(_ ranges: ClosedRange<Int>...) -> Self {
        var copy = self
        let highlights = ranges.map { "\($0.lowerBound)-\($0.upperBound)" }
        let dataLine = highlights.joined(separator: ",")
        copy.attributes.append(dataAttributes: .init(name: "line", value: dataLine))
        return copy
    }

    /// A code block with highlighted lines and ranges.
    /// - Parameters:
    ///   - lines: Individual line numbers to highlight.
    ///   - ranges: Ranges of lines to highlight.
    /// - Returns: A copy of this code block with the specified lines highlighted.
    public func highlightedLines(_ lines: Int..., ranges: ClosedRange<Int>...) -> Self {
        let singleLines = lines.map { "\($0)" }
        let rangeLines = ranges.map { "\($0.lowerBound)-\($0.upperBound)" }
        let allHighlights = singleLines + rangeLines

        var copy = self
        let dataLine = allHighlights.joined(separator: ",")
        copy.attributes.append(dataAttributes: .init(name: "line", value: dataLine))
        return copy
    }

    /// Configures whether line numbers are shown for this code block.
    /// - Parameter visibility: The visibility configuration for line numbers,
    /// including start line and text wrapping options.
    /// - Returns: A copy of this code block with the specified line number visibility.
    public func lineNumberVisibility(_ visibility: SyntaxHighlighterConfiguration.LineNumberVisibility) -> Self {
        var copy = self
        let siteVisibility = publishingContext.site.syntaxHighlighterConfiguration.lineNumberVisibility

        switch (siteVisibility, visibility) {
        case (.visible, .hidden):
            copy.attributes.append(classes: "no-line-numbers")

        case (.hidden, .visible(let elementFirstLine, let elementWrapped)):
            copy.attributes.append(classes: "line-numbers")

            if elementFirstLine != 1 {
                copy.attributes.append(dataAttributes: .init(name: "start", value: elementFirstLine.markupDigits))
            }
            if elementWrapped {
                copy.attributes.append(styles: .init(.whiteSpace, value: "pre-wrap"))
            }

        case (.visible(let siteFirstLine, let siteWrapped), .visible(let elementFirstLine, let elementWrapped)):
            if elementFirstLine != siteFirstLine {
                copy.attributes.append(dataAttributes: .init(name: "start", value: elementFirstLine.markupDigits))
            }
            if elementWrapped != siteWrapped {
                copy.attributes.append(styles: .init(.whiteSpace, value: elementWrapped ? "pre-wrap" : "pre"))
            }

        default:
            break
        }

        return copy
    }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        // A site with no highlighter theme still gets its code blocks, unstyled, and
        // the build reports what is missing – once, however many blocks there are.
        if publishingContext.site.allHighlighterThemes.isEmpty {
            let alreadyReported = publishingContext.errors.contains { error in
                if case .missingDefaultSyntaxHighlighterTheme = error { true } else { false }
            }

            if alreadyReported == false {
                publishingContext.addError(.missingDefaultSyntaxHighlighterTheme)
            }
        }

        if let language {
            publishingContext.syntaxHighlighters.append(language)
            return Markup("""
            <pre\(attributes)>\
            <code class=\"language-\(language)\">\
            \(content.escapedForHTMLKeepingCharacterReferences())\
            </code>\
            </pre>
            """)
        } else {
            return Markup("""
            <pre\(attributes)>\
            <code>\(content.escapedForHTMLKeepingCharacterReferences())</code>\
            </pre>
            """)
        }
    }
}
