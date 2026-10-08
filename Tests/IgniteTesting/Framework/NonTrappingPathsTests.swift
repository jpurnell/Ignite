//
//  NonTrappingPathsTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A navigation item written outside Ignite, with content of its own.
private struct HomeNavigationItem: HTML, NavigationItem {
    var navigationBarVisibility: NavigationBarVisibility = .automatic

    var body: some HTML {
        Text("Home")
    }
}

/// An inline navigation item written outside Ignite.
private struct InlineNavigationItem: InlineElement, NavigationItem {
    var navigationBarVisibility: NavigationBarVisibility = .automatic

    var body: some InlineElement {
        Span("Home")
    }
}

/// A form item written outside Ignite, with content of its own.
private struct NoticeFormItem: HTML, FormItem {
    var body: some HTML {
        Text("Required fields are marked.")
    }
}

/// An inline form item written outside Ignite.
private struct InlineFormItem: InlineElement, FormItem {
    var body: some InlineElement {
        Span("Required")
    }
}

/// A layout whose body is an inline element rather than a document, a body or block HTML.
private struct SpanLayout: Layout {
    var body: Span {
        return Span("Just a span")
    }
}

/// Paths through public API that used to stop the process on a mistake in a site, and now
/// produce markup and, where the mistake is the author's, a build warning.
@Suite("Non-trapping paths Tests")
class NonTrappingPathsTests: IgniteTestSuite {
    // MARK: - Keyframe positions

    @Test("A keyframe position inside 0% to 100% is kept and warns of nothing", .publishingContext(),
          arguments: [0.0, 12.5, 50, 100])
    func keyframeInRange(position: Double) {
        let frame = KeyframeProxy()(Percentage(position))

        #expect(frame.position == Percentage(position))
        #expect(publishingContext.warnings.isEmpty)
    }

    @Test("A keyframe position outside 0% to 100% is moved to the nearest end", .publishingContext(), arguments: zip(
        [150.0, 100.5, -10, -0.001, Double.infinity, -Double.infinity],
        [100.0, 100, 0, 0, 100, 0]))
    func keyframeOutOfRange(position: Double, clamped: Double) {
        let frame = KeyframeProxy()(Percentage(position))

        #expect(frame.position == Percentage(clamped))
        #expect(Array(publishingContext.warnings) == [
            "A keyframe was placed at \(position)%, outside 0% through 100%. It was moved to \(clamped)%."
        ])
    }

    @Test("A keyframe position that is not a number is placed at 0%", .publishingContext())
    func keyframeNotANumber() {
        let frame = Keyframe(Percentage(.nan))

        #expect(frame.position == 0%)
        #expect(Array(publishingContext.warnings) == [
            "A keyframe was placed at nan%, outside 0% through 100%. It was moved to 0.0%."
        ])
    }

    // MARK: - Placeholder text

    @Test("A placeholder of one word or more is unchanged", .publishingContext())
    func placeholderOfAtLeastOneWord() {
        #expect(Text(placeholderLength: 1).markupString() == "<p>Lorem.</p>")
        #expect(Text(placeholderLength: 5).markupString() == "<p>Lorem ipsum dolor sit amet.</p>")
        #expect(publishingContext.warnings.isEmpty)
    }

    @Test("A placeholder of fewer than one word is empty text and a warning", .publishingContext(),
          arguments: [0, -1, Int.min])
    func placeholderOfNoWords(length: Int) {
        #expect(Text(placeholderLength: length).markupString() == "<p></p>")
        #expect(Array(publishingContext.warnings) == [
            "Text(placeholderLength:) was asked for \(length) words; it needs at least 1. The text was left empty."
        ])
    }

    // MARK: - Article type

    @Test("An article with no type has an empty type", .publishingContext())
    func articleWithoutType() {
        #expect(Article().type == "")
        #expect(Article.empty.type == "")
    }

    @Test("An article's type is still read from its metadata", .publishingContext())
    func articleWithType() {
        var article = Article()
        article.metadata["type"] = "stories"
        #expect(article.type == "stories")

        article.metadata["type"] = 7
        #expect(article.type == "")
    }

    // MARK: - Navigation and form items

    @Test("A navigation item written outside Ignite renders its body", .publishingContext())
    func customNavigationItem() {
        #expect(HomeNavigationItem().markupString() == "<p>Home</p>")
        #expect(InlineNavigationItem().markupString() == "<span>Home</span>")
    }

    @Test("A form item written outside Ignite renders its body", .publishingContext())
    func customFormItem() {
        #expect(NoticeFormItem().markupString() == "<p>Required fields are marked.</p>")
        #expect(InlineFormItem().markupString() == "<span>Required</span>")
    }

    // MARK: - Feed images

    @Test("A feed image within the RSS limits is stored as given", .publishingContext(), arguments: zip(
        [1, 100, 144], [1, 200, 400]))
    func feedImageWithinLimits(width: Int, height: Int) {
        let image = FeedConfiguration.FeedImage(url: "/icon.png", width: width, height: height)

        #expect(image.width == width)
        #expect(image.height == height)
        #expect(publishingContext.warnings.isEmpty)
    }

    @Test("A feed image larger than RSS allows is declared at the limit", .publishingContext(), arguments: [
        [145, 200, 144, 200], [100, 401, 100, 400], [1000, 1000, 144, 400]
    ])
    func feedImageBeyondLimits(sizes: [Int]) throws {
        try #require(sizes.count == 4)
        let (width, height, declaredWidth, declaredHeight) = (sizes[0], sizes[1], sizes[2], sizes[3])
        let image = FeedConfiguration.FeedImage(url: "/icon.png", width: width, height: height)

        #expect(image.url == "/icon.png")
        #expect(image.width == declaredWidth)
        #expect(image.height == declaredHeight)
        #expect(Array(publishingContext.warnings) == [
            """
            The feed image /icon.png was given as \(width) by \(height) pixels, but RSS allows at most \
            144 by 400. It is declared as \(declaredWidth) by \(declaredHeight).
            """
        ])
    }

    // MARK: - Layouts

    @Test("A layout whose body is not a document, a body or block HTML still renders it", .publishingContext())
    func layoutWithInlineBody() {
        let content = SpanLayout().documentContent()

        #expect(content.body.markupString() == """
        <body class="container"><span>Just a span</span>\
        <script src="/js/bootstrap.bundle.min.js"></script><script src="/js/ignite-core.js"></script></body>
        """)
    }

    // MARK: - Accordion items

    @Test("An accordion item rendered outside an accordion renders and warns", .publishingContext())
    func accordionItemWithoutAccordion() throws {
        let output = Item("Shipping") { Text("Three days.") }.markupString()

        let itemID = "ig-accordion-item-1"
        #expect(output == """
        <div class="accordion-item"><h2 class="accordion-header">\
        <button type="button" class="accordion-button collapsed btn" data-bs-toggle="collapse" \
        data-bs-target="#\(itemID)" aria-expanded="false" aria-controls="\(itemID)">Shipping</button></h2>\
        <div id="\(itemID)" class="accordion-collapse collapse">\
        <div class="accordion-body"><p>Three days.</p></div></div></div>
        """)
        #expect(Array(publishingContext.warnings) == [
            "An accordion Item was rendered outside an Accordion. It opens and closes on its own, without accordion styling."
        ])
    }
}

/// Rendering outside a publish: there is no context to read a site from or to record
/// anything into, and that must not stop the process.
@Suite("Rendering outside a publishing context")
struct RenderingOutsidePublishingContextTests {
    @Test("There is no current context in a test that does not ask for one")
    func noCurrentContext() {
        #expect(PublishingContext.current == nil)
    }

    @Test("Elements that read the site render with a placeholder site's defaults")
    func elementsRender() {
        #expect(Title("About").markupString() == "<title>About</title>")
        #expect(Text("Hello").markupString() == "<p>Hello</p>")
        #expect(Script(file: "/code.js").markupString() == #"<script src="/code.js"></script>"#)
    }

    @Test("Each access outside a publish gets a context of its own")
    func detachedContextsAreNotShared() {
        let first = PublishingContext.shared
        let second = PublishingContext.shared

        #expect(first !== second)
        #expect(first.site.name == "")
        #expect(first.warnings.isEmpty)

        first.addWarning("Seen by nobody")
        #expect(second.warnings.isEmpty)
        #expect(PublishingContext.shared.warnings.isEmpty)
    }

    @Test("Inside a publish, shared is the publish's own context", .publishingContext())
    func sharedInsidePublish() throws {
        let current = try #require(PublishingContext.current)

        #expect(PublishingContext.shared === current)
        #expect(current.site.name == "My Test Site")
    }

    @Test("A mistake recorded outside a publish does not stop the process")
    func warningsOutsidePublish() {
        #expect(KeyframeProxy()(250%).position == 100%)
        #expect(Text(placeholderLength: 0).markupString() == "<p></p>")
    }
}
