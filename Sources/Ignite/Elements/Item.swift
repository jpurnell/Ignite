//
// Item.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// One item inside an accordion.
public struct Item: HTML {
    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The title to show for this item. Clicking this title will display the
    /// item's contents.
    private var title: any InlineElement

    /// Whether this accordion item should start open or not.
    private var startsOpen: Bool

    /// The contents of this accordion item.
    private var contents: any BodyElement

    /// Used when rendering this accordion item so that we can send change
    /// notifications back the parent accordion object.
    private var parentID: String?

    /// The background color of the accordion item content.
    private var contentBackground: Color?

    /// Used when rendering this accordion item so that we can know whether
    /// opening this item should also close other items.
    private var parentOpenMode: Accordion.OpenMode?

    /// Creates a new `Item` object from the provided title and contents.
    /// - Parameters:
    ///   - header: The title to use as the header for this accordion item.
    ///   - startsOpen: Set this to true when this item should be open when
    ///   your page is initially loaded.
    ///   - content: A block element builder that creates the contents
    ///   for this accordion item.
    public init(
        _ header: some InlineElement,
        startsOpen: Bool = false,
        @HTMLBuilder content: () -> some HTML
    ) {
        self.title = header
        self.startsOpen = startsOpen
        self.contents = content()
    }

    /// Creates a new `Item` object from the provided title and contents.
    /// - Parameters:
    ///   - startsOpen: Set this to true when this item should be open when
    ///   your page is initially loaded.
    ///   - content: A block element builder that creates the contents
    ///   for this accordion item.
    ///   - header: An inline element builder that creates the title to use
    ///   as the header for this accordion item.
    public init(
        startsOpen: Bool = false,
        @HTMLBuilder content: () -> some HTML,
        @InlineElementBuilder header: () -> some InlineElement
    ) {
        self.startsOpen = startsOpen
        self.contents = content()
        self.title = header()
    }

    /// Sets the background color for the accordion item's content area.
    /// - Parameter color: The color to use for the content background.
    /// - Returns: A modified copy of this accordion item.
    public func contentBackground(_ color: Color) -> Self {
        var copy = self
        copy.contentBackground = color
        return copy
    }

    /// Used during rendering to assign this accordion item to a particular parent,
    /// so our open behavior works correctly.
    func assigned(to parentID: String, openMode: Accordion.OpenMode) -> Self {
        var copy = self
        copy.parentID = parentID
        copy.parentOpenMode = openMode
        return copy
    }

    /// Renders this item as Bootstrap's `accordion-item`.
    ///
    /// An `Accordion` tells each of its items which accordion it belongs to before
    /// rendering it. An item rendered anywhere else has no accordion: it still renders,
    /// and opens and closes on its own, but Bootstrap's accordion styling comes from the
    /// enclosing accordion, so a warning is added to the build.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        if parentID == nil {
            PublishingContext.warn("""
            An accordion Item was rendered outside an Accordion. \
            It opens and closes on its own, without accordion styling.
            """)
        }

        let parentID = parentID ?? "ig-accordion"
        let parentOpenMode = parentOpenMode ?? .all
        let itemID = "\(parentID)-item-\(PublishingContext.nextElementNumber())"

        return Section {
            Text {
                Button(title)
                    .componentPart()
                    .class("accordion-button", startsOpen ? "" : "collapsed")
                    .data("bs-toggle", "collapse")
                    .data("bs-target", "#\(itemID)")
                    .aria(.expanded, startsOpen ? "true" : "false")
                    .aria(.controls, itemID)
            }
            .font(.title2)
            .class("accordion-header")

            Section {
                Section(contents)
                    .class("accordion-body")
            }
            .id(itemID)
            .class("accordion-collapse", "collapse", startsOpen ? "show" : nil)
            .data("bs-parent", parentOpenMode == .individual ? "#\(parentID)" : "")
            .style(contentBackground.map { InlineStyle(.background, value: $0.description) })
        }
        .class("accordion-item")
        .markup()
    }
}
