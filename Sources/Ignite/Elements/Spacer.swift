//
// Spacer.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Creates vertical space of a specific value.
public struct Spacer: HTML, NavigationItem {
    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// How a `NavigationBar` displays this item at different breakpoints.
    public var navigationBarVisibility: NavigationBarVisibility = .automatic

    /// The amount of space to occupy.
    private var spacingAmount: SpacingType

    /// Whether the spacer is used horizontally or vertically.
    private var axis: Axis = .vertical

    /// Creates a new `Spacer` that uses all available space.
    public init() {
        spacingAmount = .automatic
    }

    /// Creates a new `Spacer` with a size in pixels of your choosing.
    /// - Parameter size: The amount of vertical space this `Spacer`
    /// should occupy.
    public init(size: Int) {
        spacingAmount = .exact(size)
    }

    /// Creates a new `Spacer` using adaptive sizing.
    /// - Parameter size: The amount of margin to apply, specified as a
    /// `SpacingAmount` case.
    public init(size: SpacingAmount) {
        spacingAmount = .semantic(size)
    }

    /// Configures the axis of this spacer.
    /// - Parameter axis: The lateral direction of the spacer.
    /// - Returns: A new `Spacer` with the specified axis.
    func axis(_ axis: Axis) -> Self {
        var copy = self
        copy.axis = axis
        return copy
    }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        // `axis` is a set, so each axis is looked for in it rather than compared with it:
        // a spacer on both axes takes space on both.
        let isHorizontal = axis.contains(.horizontal)
        let isVertical = axis.contains(.vertical)

        switch spacingAmount {
        case .automatic:
            return Section {}
                .class(isHorizontal ? "ms-auto" : nil)
                .class(isVertical ? "mt-auto" : nil)
                .markup()
        case .semantic(let spacingAmount):
            var edges: Edge = []
            if isVertical { edges.insert(.top) }
            if isHorizontal { edges.insert(.leading) }
            return Section {}
                .margin(edges, spacingAmount)
                .markup()
        case .exact(let int):
            return Section {}
                .frame(width: isHorizontal ? .px(int) : nil)
                .frame(height: isVertical ? .px(int) : nil)
                .markup()
        }
    }
}
