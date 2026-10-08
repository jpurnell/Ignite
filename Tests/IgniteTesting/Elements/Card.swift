//
//  Card.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `Card` element.
@Suite("Card Tests")
class CardTests: IgniteTestSuite {
    @Test("Basic Card", .publishingContext())
    func basicCard() async throws {
        let element = Card {
            "Some text wrapped in a card"
        }

        let output = element.markup()

        #expect(output.string == """
        <div class="card"><div class="card-body">Some text wrapped in a card</div></div>
        """)
    }

    @Test("Basic Card with Image", .publishingContext())
    func basicCardWithImage() async throws {
        let element = Card(imageName: "dog.jpg") {
            "Some text wrapped in a card"
        }

        let output = element.markup()

        #expect(output.string == """
        <div class="card"><img src="dog.jpg" alt="" class="card-img-top" />\
        <div class="card-body">Some text wrapped in a card</div></div>
        """)
    }

    @Test("Basic Card with Header and Footer", .publishingContext())
    func basicCardWithHeaderAndFooter() async throws {
        let element = Card {
            "Some text wrapped in a card"
        } header: {
            "Header"
        } footer: {
            "A footer"
        }

        let output = element.markup()

        #expect(output.string == """
        <div class="card"><div class="card-header">Header</div><div class="card-body">Some text wrapped in a card</div>\
        <div class="card-footer text-body-secondary">A footer</div></div>
        """)
    }

    @Test("Complex Card", .publishingContext())
    func complexCard() async throws {
        let element = Card(imageName: "/images/photos/dishwasher.jpg") {
            Text("Before putting your dishes into the dishwasher, give them a quick pre-clean.")

            Link("Back to the homepage", target: "/")
                .linkStyle(.button)
        }
        .frame(maxWidth: 500)

        let output = element.markup()

        #expect(output.string == """
        <div class="card" style="width: 100%; max-width: 500px">\
        <img src="/images/photos/dishwasher.jpg" alt="" class="card-img-top" /><div class="card-body">\
        <p class="card-text">Before putting your dishes into the dishwasher, give them a quick pre-clean.</p>\
        <a href="/" class="card-link btn btn-primary">Back to the homepage</a></div></div>
        """)
    }

    @Test("Card Styles", .publishingContext(), arguments: zip(
        Card.Style.allCases,
        ["card", "card", "card"]))
    func cardStyles(style: Card.Style, expectedClass: String) async throws {
        let element = Card {
            "Placeholder"
        }
        .cardStyle(style)

        let output = element.markupString()

        #expect(output == """
        <div class="\(expectedClass)"><div class="card-body">Placeholder</div></div>
        """)
    }

    @Test("A solid card takes Bootstrap's text-bg class for its role", .publishingContext(), arguments: zip(
        Role.standardRoles,
        ["primary", "secondary", "success", "danger", "warning", "info", "light", "dark"]))
    func solidCardWithRole(role: Role, name: String) async throws {
        let implicit = Card { "Placeholder" }.role(role)
        let explicit = Card { "Placeholder" }.role(role).cardStyle(.solid)
        let expected = """
        <div class="card text-bg-\(name)"><div class="card-body">Placeholder</div></div>
        """

        #expect(implicit.markupString() == expected)
        #expect(explicit.markupString() == expected)
    }

    @Test("A bordered card takes Bootstrap's border class for its role", .publishingContext(), arguments: zip(
        Role.standardRoles,
        ["primary", "secondary", "success", "danger", "warning", "info", "light", "dark"]))
    func borderedCardWithRole(role: Role, name: String) async throws {
        let element = Card { "Placeholder" }.role(role).cardStyle(.bordered)

        #expect(element.markupString() == """
        <div class="card border-\(name)"><div class="card-body">Placeholder</div></div>
        """)
    }

    @Test("A card whose role names no Bootstrap color is a plain card", .publishingContext(),
          arguments: [Role.default, .none, .close], [Card.Style.solid, .bordered])
    func cardWithoutContextualRole(role: Role, style: Card.Style) async throws {
        let element = Card { "Placeholder" }.role(role).cardStyle(style)

        #expect(element.markupString() == """
        <div class="card"><div class="card-body">Placeholder</div></div>
        """)
    }

    @Test("Card Content Position: Top", .publishingContext())
    func contentPositionTop() async throws {
        let element = Card(imageName: "image.jpg") {
            "Placeholder"
        }
        .contentPosition(.top)

        let output = element.markupString()

        #expect(output == """
        <div class="card"><div class="card-body">Placeholder</div>\
        <img src="image.jpg" alt="" class="card-img-bottom" /></div>
        """)
    }

    @Test("Card Content Position: Bottom", .publishingContext())
    func contentPositionBottom() async throws {
        let element = Card(imageName: "image.jpg") {
            "Placeholder"
        }
        .contentPosition(.bottom)

        let output = element.markupString()

        #expect(output == """
        <div class="card"><img src="image.jpg" alt="" class="card-img-top" />\
        <div class="card-body">Placeholder</div></div>
        """)
    }

    @Test("Card Content Position: Overlay", .publishingContext())
    func contentPositionOverlay() async throws {
        let element = Card(imageName: "image.jpg") {
            "Placeholder"
        }
        .contentPosition(.overlay)

        let output = element.markupString()

        #expect(output == """
        <div class="card"><img src="image.jpg" alt="" class="card-img" />\
        <div class="card-img-overlay text-start align-content-start">Placeholder</div></div>
        """)
    }
}
