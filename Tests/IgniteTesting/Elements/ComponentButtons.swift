//
// ComponentButtons.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that the buttons Ignite draws inside Bootstrap components carry the classes
/// Bootstrap's own markup gives them, and not `btn` as well.
///
/// `btn` is the class of a standalone button. Added to a component's button it brings a
/// button's hover rules with it, which are more specific than the component's own: a
/// navigation bar's toggler lost its border under the pointer.
@Suite("Component Button Tests")
class ComponentButtonTests: IgniteTestSuite {
    @Test("An accordion's button is Bootstrap's accordion button", .publishingContext())
    func accordionButton() {
        let output = Accordion { Item("Title") { Text("Body") } }.markupString()
        #expect(output == """
        <div id="ig-accordion-1" class="accordion"><div class="accordion-item">\
        <h2 class="accordion-header">\
        <button type="button" class="accordion-button collapsed" data-bs-toggle="collapse" \
        data-bs-target="#ig-accordion-1-item-2" aria-expanded="false" aria-controls="ig-accordion-1-item-2">\
        Title</button></h2>\
        <div id="ig-accordion-1-item-2" class="accordion-collapse collapse" data-bs-parent="#ig-accordion-1">\
        <div class="accordion-body"><p>Body</p></div></div></div></div>
        """)
    }

    @Test("A carousel's indicators and controls are Bootstrap's", .publishingContext())
    func carouselButtons() {
        let output = Carousel { Slide { Text("One") }; Slide { Text("Two") } }.markupString()
        #expect(output.contains("""
        <div class="carousel-indicators">\
        <button type="button" class="active" data-bs-target="#ig-carousel-1" data-bs-slide-to="0" \
        aria-current="true" aria-label="Slide 1"></button>\
        <button type="button" data-bs-target="#ig-carousel-1" data-bs-slide-to="1" aria-label="Slide 2"></button>\
        </div>
        """))
        #expect(output.contains("""
        <button type="button" class="carousel-control-prev" data-bs-target="#ig-carousel-1" data-bs-slide="prev">\
        <span class="carousel-control-prev-icon" aria-hidden="true"></span>\
        <span class="visually-hidden">Previous</span></button>\
        <button type="button" class="carousel-control-next" data-bs-target="#ig-carousel-1" data-bs-slide="next">\
        <span class="carousel-control-next-icon" aria-hidden="true"></span>\
        <span class="visually-hidden">Next</span></button>
        """))
    }

    @Test("A navigation bar's toggler is Bootstrap's", .publishingContext())
    func navigationBarToggler() {
        let output = NavigationBar(logo: "Site", items: { Link("A", target: "/a") }).markupString()
        #expect(output.contains("""
        <button type="button" class="navbar-toggler" data-bs-toggle="collapse" \
        data-bs-target="#navbarCollapse" aria-controls="navbarCollapse" aria-expanded="false" \
        aria-label="Toggle navigation"><span class="navbar-toggler-icon"></span></button>
        """))
    }

    @Test("A button of your own keeps the button class whatever else it is given", .publishingContext())
    func ordinaryButtonsUnchanged() {
        #expect(Button("Go").class("accordion-button").markupString()
            == #"<button type="button" class="accordion-button btn">Go</button>"#)
        #expect(Dropdown("Menu") {}.markupString() == """
        <div class="dropdown"><button type="button" class="btn dropdown-toggle" \
        data-bs-toggle="dropdown" aria-expanded="false">Menu</button><ul class="dropdown-menu"></ul></div>
        """)
    }
}
