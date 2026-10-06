//
// Card.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A group of information placed inside a gently rounded
public struct Card: HTML {
    /// Styling for this card.
    public enum Style: CaseIterable, Sendable {
        /// Default styling.
        case `default`

        /// Solid background color.
        case solid

        /// Solid border color.
        case bordered
    }

    /// Where to position the content of the card relative to it image.
    public enum ContentPosition: CaseIterable, Sendable {
        /// The content positions used when iterating over every case: below the image, above
        /// it, and overlaid with top-leading alignment. The other overlay alignments are not listed.
        public static let allCases: [Card.ContentPosition] = [
            .bottom, .top, .overlay(alignment: .topLeading)
        ]

        /// Positions content below the image.
        case bottom

        /// Positions content above the image.
        case top

        /// Positions content over the image.
        case overlay(alignment: ContentAlignment)

        // Static entries for backward compatibilty
        /// The default content position, which places content below the image.
        public static let `default` = Self.bottom
        /// Positions content over the image, aligned to its top-leading corner.
        public static let overlay = Self.overlay(alignment: .topLeading)

        // MARK: Helpers for `render`

        var imageClass: String {
            switch self {
            case .bottom:
                "card-img-top"
            case .top:
                "card-img-bottom"
            case .overlay:
                "card-img"
            }
        }

        var bodyClasses: [String] {
            switch self {
            case .overlay(let alignment):
                ["card-img-overlay", alignment.textAlignment.rawValue, alignment.verticalAlignment.rawValue]
            default:
                ["card-body"]
            }
        }

        var addImageFirst: Bool {
            switch self {
            case .bottom, .overlay:
                true
            case .top:
                false
            }
        }
    }

    enum TextAlignment: String, CaseIterable, Sendable {
        case start = "text-start"
        case center = "text-center"
        case end = "text-end"
    }

    enum VerticalAlignment: String, CaseIterable, Sendable {
        case start = "align-content-start"
        case center = "align-content-center"
        case end = "align-content-end"
    }

    /// Where content sits inside a card when it is overlaid on the card's image.
    ///
    /// The horizontal part becomes one of Bootstrap's `text-start`, `text-center` or `text-end`
    /// classes, and the vertical part one of `align-content-start`, `align-content-center`
    /// or `align-content-end`.
    public enum ContentAlignment: CaseIterable, Sendable {
        /// Content is at the top, aligned to the leading edge.
        case topLeading

        /// Content is at the top, centered horizontally.
        case top

        /// Content is at the top, aligned to the trailing edge.
        case topTrailing

        /// Content is centered vertically, aligned to the leading edge.
        case leading

        /// Content is centered both vertically and horizontally.
        case center

        /// Content is centered vertically, aligned to the trailing edge.
        case trailing

        /// Content is at the bottom, aligned to the leading edge.
        case bottomLeading

        /// Content is at the bottom, centered horizontally.
        case bottom

        /// Content is at the bottom, aligned to the trailing edge.
        case bottomTrailing

        var textAlignment: TextAlignment {
            switch self {
            case .topLeading, .leading, .bottomLeading:
                .start
            case .top, .center, .bottom:
                .center
            case .topTrailing, .trailing, .bottomTrailing:
                .end
            }
        }

        var verticalAlignment: VerticalAlignment {
            switch self {
            case .topLeading, .top, .topTrailing:
                .start
            case .leading, .center, .trailing:
                .center
            case .bottomLeading, .bottom, .bottomTrailing:
                .end
            }
        }

        /// The default alignment for overlaid content, which is top-leading.
        public static let `default` = Self.topLeading
    }

    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    var role = Role.default
    var style = Style.default

    var contentPosition = ContentPosition.default
    var imageOpacity = 1.0

    var image: Image?
    private var header: HTMLCollection
    private var footer: HTMLCollection
    private var items: HTMLCollection

    var cardClasses: String? {
        switch style {
        case .default:
            nil
        case .solid:
            "text-bg-\(role.rawValue)"
        case .bordered:
            "border-\(role.rawValue)"
        }
    }

    /// Creates a card with body content and, optionally, an image, a header and a footer.
    /// - Parameters:
    ///   - imageName: The path of an image to show in the card, relative to the root of
    ///   your site, e.g. /images/dog.jpg. The image is decorative, so it is hidden from
    ///   screen readers. Defaults to `nil`, meaning the card has no image.
    ///   - body: The main content of the card, placed in Bootstrap's `card-body`.
    ///   - header: Content for the `card-header` at the top of the card. Defaults to no header.
    ///   - footer: Content for the `card-footer` at the bottom of the card. Defaults to no footer.
    public init(
        imageName: String? = nil,
        @HTMLBuilder body: () -> some BodyElement,
        @HTMLBuilder header: () -> some BodyElement = { EmptyHTML() },
        @HTMLBuilder footer: () -> some BodyElement = { EmptyHTML() }
    ) {
        if let imageName {
            self.image = Image(decorative: imageName)
        }

        self.header = HTMLCollection(header)
        self.footer = HTMLCollection(footer)
        self.items = HTMLCollection(body)
    }

    /// Sets the role for this card, which controls its color.
    ///
    /// A card that still has the default style is switched to `.solid`, because the
    /// default style does not show the role at all.
    /// - Parameter role: The new role to apply.
    /// - Returns: A new `Card` instance with the updated role.
    public func role(_ role: Role) -> Card {
        var copy = self
        copy.role = role

        if style == .default {
            copy.style = .solid
        }

        return copy
    }

    /// Adjusts the rendering style of this card.
    /// - Parameter style: The new card style to use.
    /// - Returns: A new `Card` instance with the updated style.
    public func cardStyle(_ style: Style) -> Card {
        var copy = self
        copy.style = style
        return copy
    }

    /// Adjusts the position of this card's content relative to its image.
    /// - Parameter newPosition: The new content positio for this card.
    /// - Returns: A new `Card` instance with the updated content position.
    public func contentPosition(_ newPosition: ContentPosition) -> Self {
        var copy = self
        copy.contentPosition = newPosition
        return copy
    }

    /// Adjusts the opacity of the image for this card. Use values
    /// lower than 1.0 to progressively dim the image.
    /// - Parameter opacity: The new opacity for this card.
    /// - Returns: A new `Card` instance with the updated image opacity.
    public func imageOpacity(_ opacity: Double) -> Self {
        var copy = self
        copy.imageOpacity = opacity
        return copy
    }

    /// Renders this card as a `<div>` with Bootstrap's `card` class, containing its image,
    /// header, body and footer in the order its content position asks for.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        Section {
            // An opacity of exactly 1 is the stored default meaning "not dimmed". It is
            // assigned, never computed, so this is an exact IEEE 754 comparison by intent.
            if let image, contentPosition.addImageFirst {
                if !imageOpacity.isEqual(to: 1) {
                    image
                        .class(contentPosition.imageClass)
                        .style(.opacity, imageOpacity.description)
                } else {
                    image
                        .class(contentPosition.imageClass)
                }
            }

            if header.isEmpty == false {
                renderHeader()
            }

            renderItems()

            if let image, !contentPosition.addImageFirst {
                if !imageOpacity.isEqual(to: 1) {
                    image
                        .class(contentPosition.imageClass)
                        .style(.opacity, imageOpacity.description)
                } else {
                    image
                        .class(contentPosition.imageClass)
                }
            }

            if footer.isEmpty == false {
                renderFooter()
            }
        }
        .attributes(attributes)
        .class("card")
        .class(cardClasses)
        .markup()
    }

    private func renderHeader() -> some HTML {
        Section(header)
            .class("card-header")
    }

    private func renderItems() -> some HTML {
        Section {
            ForEach(items) { item in
                switch item {
                case let text as Text where text.font == .body || text.font == .lead:
                    text.class("card-text")
                case let text as Text:
                    text.class("card-title")
                case is Link, is LinkGroup:
                    AnyHTML(item).class("card-link")
                case let image as Image:
                    image.class("card-img")
                default:
                    AnyHTML(item)
                }
            }
        }
        .class(contentPosition.bodyClasses)
    }

    private func renderFooter() -> some HTML {
        Section(footer)
            .class("card-footer", "text-body-secondary")
    }
}
