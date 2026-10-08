//
// Badge.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A small, capsule-shaped piece of information, such as a tag.
public struct Badge: InlineElement {
    /// The content and behavior of this HTML.
    public var body: some InlineElement { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The different options for styling this badge.
    public enum Style: CaseIterable {
        case `default`, subtle, subtleBordered
    }

    private var text: any InlineElement
    private var style = Style.default
    private var role = Role.default

    var badgeClasses: [String] {
        var outputClasses = ["badge"]
        outputClasses.append(contentsOf: attributes.classes)

        // Bootstrap defines these classes for its eight theme colors only; a badge whose
        // role is not one of them has no color classes to carry.
        let color = role.themeColorName

        switch style {
        case .default:
            if let color {
                outputClasses.append("text-bg-\(color)")
            }

        case .subtle:
            if let color {
                outputClasses.append("bg-\(color)-subtle")
                outputClasses.append("text-\(color)-emphasis")
            }

        case .subtleBordered:
            if let color {
                outputClasses.append("bg-\(color)-subtle")
            }

            outputClasses.append("border")

            if let color {
                outputClasses.append("border-\(color)-subtle")
                outputClasses.append("text-\(color)-emphasis")
            }
        }

        outputClasses.append("rounded-pill")
        return outputClasses
    }

    /// Creates a badge from an inline element.
    /// - Parameter text: The inline content to show inside the badge.
    public init(_ text: any InlineElement) {
        self.text = text
    }

    /// Creates a badge from a string.
    /// - Parameter text: The text to show inside the badge.
    public init(_ text: String) {
        self.text = text
    }

    /// Sets the role for this badge, which controls its color.
    /// - Parameter role: The new role to apply. With the default badge style this adds
    /// Bootstrap's `text-bg-<role>` class; the subtle styles add `bg-<role>-subtle` and
    /// `text-<role>-emphasis` instead.
    /// - Returns: A new `Badge` instance with the updated role.
    public func role(_ role: Role) -> Badge {
        var copy = self
        copy.role = role
        return copy
    }

    /// Adjusts the visual style of this badge.
    /// - Parameter style: The new style to apply.
    /// - Returns: A new `Badge` instance with the updated style.
    public func badgeStyle(_ style: Style) -> Badge {
        var copy = self
        copy.style = style
        return copy
    }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        let badgeAttributes = attributes.appending(classes: badgeClasses)
        return Span(text)
            .attributes(badgeAttributes)
            .markup()
    }
}
