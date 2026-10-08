//
// AnimationFrame.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A single keyframe in an animation sequence.
public typealias Keyframe = Animation.Frame

public extension Animation {
    /// A single keyframe in an animation sequence.
    struct Frame: Hashable, Sendable {
        /// The position in the animation timeline, always between `0%` and `100%`
        let position: Percentage

        /// The property transformations to apply at this position
        var styles: OrderedSet<InlineStyle>

        /// Creates a frame with a single predefined animation.
        ///
        /// CSS has no keyframe before `0%` or after `100%`. A position outside that range
        /// is a mistake in the site rather than a reason to stop building it, so it is
        /// moved to the nearer end – a position that is not a number goes to `0%` – and a
        /// warning is added to the build.
        init(_ position: Percentage, data: OrderedSet<InlineStyle> = []) {
            let clamped = Self.clamped(position)
            if clamped != position {
                PublishingContext.warn("""
                A keyframe was placed at \(position.value)%, outside 0% through 100%. \
                It was moved to \(clamped.value)%.
                """)
            }

            self.position = clamped
            self.styles = data
        }

        /// The nearest position to `position` that lies between `0%` and `100%`.
        private static func clamped(_ position: Percentage) -> Percentage {
            // NaN fails every comparison, so it leaves through the first guard.
            guard position.value > 0 else { return 0% }
            guard position.value < 100 else { return 100% }
            return position
        }
    }

    /// A simple property-value pair to store inline styles
    struct InlineStyle: CustomStringConvertible, Hashable, Equatable, Sendable {
        /// The property, e.g. `\.color`.
        var property: String

        /// The declaration's value, e.g. "blue".
        var value: String

        init(_ property: AnimatableProperty, value: String) {
            self.property = property.rawValue
            self.value = value
        }

        /// The full declaration, e.g. "color: blue""
        public var description: String {
            property + ": " + value
        }
    }
}

public extension Keyframe {
    /// Sets a color for this keyframe
    /// - Parameters:
    ///   - area: Which color property to animate (text or background). Default is `.foreground`.
    ///   - value: The color to animate to
    /// - Returns: A new keyframe with the color animation applied
    func color(_ area: ColorArea = .foreground, to value: Color) -> Keyframe {
        var copy = self
        copy.styles.append(.init(area.property, value: value.description))
        return copy
    }

    /// Sets the scale transform for this keyframe
    /// - Parameter value: The scale factor to animate to (e.g., 1.5 for 150% size)
    /// - Returns: A new keyframe with the scale transform applied
    func scale(_ value: Double) -> Keyframe {
        var copy = self
        copy.styles.append(.init(.transform, value: "scale(\(value))"))
        return copy
    }

    /// Sets the rotation transform for this keyframe
    /// - Parameters:
    ///   - angle: The angle to rotate by
    ///   - anchor: The point around which to rotate (defaults to center)
    /// - Returns: A new keyframe with the rotation transform applied
    func rotate(_ angle: Angle, anchor: AnchorPoint = .center) -> Keyframe {
        var copy = self
        copy.styles.append(.init(.transformOrigin, value: anchor.value))
        copy.styles.append(.init(.transform, value: "rotate(\(angle.value))"))
        return copy
    }

    /// Sets a custom style transformation for this keyframe
    /// - Parameters:
    ///   - property: The CSS property to animate
    ///   - value: The CSS value
    /// - Returns: A new keyframe with the custom animation applied
    func custom(_ property: AnimatableProperty, value: String) -> Keyframe {
        var copy = self
        copy.styles.append(.init(property, value: value))
        return copy
    }
}
