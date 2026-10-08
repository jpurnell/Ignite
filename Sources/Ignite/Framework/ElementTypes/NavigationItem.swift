//
// NavigationItem.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Describes elements that can be placed into navigation bars.
/// - Warning: Do not conform to this type directly.
public protocol NavigationItem: BodyElement {
    /// How a `NavigationBar` displays this item at different breakpoints.
    var navigationBarVisibility: NavigationBarVisibility { get set }

    /// Returns a new instance with the specified visibility.
    func navigationBarVisibility(_ visibility: NavigationBarVisibility) -> Self
}

public extension NavigationItem {
    /// Returns a new instance with the specified visibility.
    /// - Parameter visibility: The visibility to apply.
    /// - Returns: A new instance with the updated visibility.
    func navigationBarVisibility(_ visibility: NavigationBarVisibility) -> Self {
        var copy = self
        copy.navigationBarVisibility = visibility
        return copy
    }
}

public extension NavigationItem where Self: HTML {
    /// Generates the complete `HTML` string representation of the element.
    ///
    /// Ignite's own conforming types render themselves. A type of your own that conforms
    /// renders its `body`, as any other element you write does.
    func markup() -> Markup {
        body.markup()
    }
}

public extension NavigationItem where Self: InlineElement {
    /// Generates the complete `HTML` string representation of the element.
    ///
    /// Ignite's own conforming types render themselves. A type of your own that conforms
    /// renders its `body`, as any other element you write does.
    func markup() -> Markup {
        body.markup()
    }
}

extension NavigationItem where Self: InlineElement {
    /// Adds a CSS class to the HTML element
    /// - Parameter className: The CSS class name to add
    /// - Returns: A modified copy of the element with the CSS class added
    func `class`(_ className: String) -> Self {
        guard !className.isEmpty else { return self }
        var copy = self
        copy.attributes.append(classes: className)
        return copy
    }
}

extension NavigationItem where Self: BodyElement {
    /// Adds a CSS class to the HTML element
    /// - Parameter className: The CSS class name to add
    /// - Returns: A modified copy of the element with the CSS class added
    func `class`(_ className: String) -> Self {
        guard !className.isEmpty else { return self }
        var copy = self
        copy.attributes.append(classes: className)
        return copy
    }

    /// Adds inline styles to the element.
    /// - Parameter styles: An array of `InlineStyle` objects
    /// - Returns: The modified `HTML` element
    func style(_ styles: [InlineStyle]) -> Self {
        guard styles.isEmpty == false else { return self }
        var copy = self
        copy.attributes.append(styles: styles)
        return copy
    }
}
