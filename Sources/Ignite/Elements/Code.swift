//
// Code.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// An inline snippet of programming code, embedded inside a larger part
/// of your page. For dedicated code blocks that sit on their own line, use
/// `CodeBlock` instead.
///
/// - Note: Write the code as it is. Angle brackets and ampersands – `Array<Int>`,
/// `a && b` – are escaped for you, so they are shown rather than read as HTML. A
/// character reference such as `&lt;` is left as it is and shows the character it names,
/// because earlier versions asked for angle brackets to be written that way; to show a
/// reference itself, write its ampersand as `&amp;`.
public struct Code: InlineElement {
    /// The content and behavior of this HTML.
    public var body: some InlineElement { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The code to display.
    private var content: String

    /// Creates a new `Code` instance from the given content.
    /// - Parameter content: The code you want to render.
    public init(_ content: String) {
        self.content = content
    }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        Markup("<code\(attributes)>\(content.escapedForHTMLKeepingCharacterReferences())</code>")
    }
}
