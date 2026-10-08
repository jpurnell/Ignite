//
// Alert.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Shows a clearly delineated box on your page, providing important information
/// or warnings to users.
public struct Alert: HTML {
    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    var content: any HTML

    var role = Role.default

    var alertClasses: [String] {
        var outputClasses = ["alert"]
        outputClasses.append(contentsOf: attributes.classes)

        if let color = role.themeColorName {
            outputClasses.append("alert-\(color)")
        }

        return outputClasses
    }

    /// Creates an alert from a page element builder.
    /// - Parameter content: The elements to show inside the alert box.
    public init(@HTMLBuilder content: () -> some HTML) {
        self.content = content()
    }

    /// Sets the role for this alert, which controls its color.
    /// - Parameter role: The new role to apply. Any role other than `.default` adds
    /// Bootstrap's `alert-<role>` class, such as `alert-danger`.
    /// - Returns: A new `Alert` instance with the updated role.
    public func role(_ role: Role) -> Alert {
        var copy = self
        copy.role = role
        return copy
    }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        Section(content)
            .class(alertClasses)
            .attributes(attributes)
            .markup()
    }
}
