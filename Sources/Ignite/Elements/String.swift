//
// String.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A small String extension that allows strings to be used directly inside HTML.
/// Useful when you don't want your text to be wrapped in a paragraph or similar.
///
/// A string used as an element is HTML, and is written to the page as it is: tags and
/// character references in it take effect, so `"Hello <strong>world</strong>"` shows
/// bold text and `"&copy;"` shows ©. That holds wherever a string stands for an element –
/// `Text("…")`, `Span("…")`, `Link("…", target:)`, `Button("…")`, a string in a builder.
/// To show a string exactly as written, call `escapedForHTML()` on it or use
/// `Text(verbatim:)`; do this for any text you did not write yourself.
///
/// Strings that are not elements are plain text, and Ignite escapes them: attribute
/// values, IDs and classes, image descriptions, accessibility labels, page titles,
/// metadata, and the title, description and tags of an article.
extension String: InlineElement, FormItem {
    /// The content and behavior of this HTML.
    public var body: some InlineElement { self }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        Markup(verbatim: self)
    }
}
