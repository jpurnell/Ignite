//
// AccessibleNames.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that the things Ignite draws without text – icons, icon buttons, unlabelled
/// fields – are either named for assistive technology or hidden from it.
@Suite("Accessible Name Tests")
class AccessibleNameTests: IgniteTestSuite {
    /// The warnings of the current build about names, leaving out the one an image
    /// file adds when the test site has no folder to look for its variants in.
    private var warnings: [String] {
        publishingContext.warnings.filter { $0.hasPrefix("Could not read the assets directory") == false }
    }

    // MARK: - Icons

    @Test("An icon with a description is an image with that name", .publishingContext())
    func describedIcon() {
        #expect(Image(systemName: "star", description: "Favourite").markupString()
            == #"<i role="img" class="bi-star" aria-label="Favourite"></i>"#)
        #expect(warnings.isEmpty)
    }

    @Test("An icon's description is escaped as an attribute value", .publishingContext())
    func describedIconIsEscaped() {
        #expect(Image(systemName: "star", description: #"Tom & "Jerry""#).markupString()
            == #"<i role="img" class="bi-star" aria-label="Tom &amp; &quot;Jerry&quot;"></i>"#)
    }

    @Test("An icon with an empty description is hidden from assistive technology", .publishingContext())
    func decorativeIcon() {
        #expect(Image(systemName: "star", description: "").markupString()
            == #"<i class="bi-star" aria-hidden="true"></i>"#)
        #expect(warnings.isEmpty)
    }

    @Test("An icon with no description is hidden, and the build says how to describe it", .publishingContext())
    func undescribedIcon() {
        #expect(Image(systemName: "star").markupString() == #"<i class="bi-star" aria-hidden="true"></i>"#)
        #expect(warnings == ["""
        star: this icon has no description, so it is hidden from screen readers. \
        Give it a description, or an empty one – Image(systemName:description:) with "" – \
        if it is decorative.
        """])
    }

    @Test("An icon described after it is created is named", .publishingContext())
    func iconDescribedLater() {
        #expect(Image(systemName: "star").accessibilityLabel("Favourite").markupString()
            == #"<i role="img" class="bi-star" aria-label="Favourite"></i>"#)
    }

    @Test("An icon given its own aria-label keeps it and is not hidden", .publishingContext())
    func iconWithOwnLabel() {
        #expect(Image(systemName: "star", description: "").aria(.label, "Mine").markupString()
            == #"<i role="img" class="bi-star" aria-label="Mine"></i>"#)
    }

    @Test("An image file still warns in the words it always has", .publishingContext())
    func undescribedImageFile() {
        #expect(Image("/images/a.png").markupString() == #"<img src="/images/a.png" alt="" />"#)
        #expect(warnings == ["""
        /images/a.png: adding images without a description is not recommended. \
        Provide a description or use Image(decorative:) to silence this warning.
        """])
    }

    // MARK: - Labels

    @Test("The icon of a label is decorative, because the title beside it says the same", .publishingContext())
    func labelIconIsDecorative() {
        #expect(Label("Home", systemImage: "house").markupString() == """
        <span style="display: inline-flex; align-items: center">\
        <i class="bi-house" style="margin-right: 10px" aria-hidden="true"></i>\
        Home\
        </span>
        """)
        #expect(Label("Logo", image: "/images/logo.png").markupString() == """
        <span style="display: inline-flex; align-items: center">\
        <img src="/images/logo.png" alt="" style="margin-right: 10px" />\
        Logo\
        </span>
        """)
        #expect(warnings.isEmpty)
    }

    // MARK: - Buttons

    @Test("The icon of a titled button is hidden, since the title names the button", .publishingContext())
    func titledIconButton() {
        #expect(Button("Go", systemImage: "star").markupString()
            == #"<button type="button" class="btn"><i class="bi bi-star" aria-hidden="true"></i> Go</button>"#)
        #expect(warnings.isEmpty)
    }

    @Test("A button whose only content is an icon is reported", .publishingContext())
    func iconOnlyButton() {
        #expect(Button("", systemImage: "star").markupString()
            == #"<button type="button" class="btn"><i class="bi bi-star" aria-hidden="true"></i> </button>"#)
        #expect(warnings == [Button.missingNameWarning])
    }

    @Test("A button with no content is reported", .publishingContext())
    func emptyButton() {
        #expect(Button().markupString() == #"<button type="button" class="btn"></button>"#)
        #expect(warnings == [Button.missingNameWarning])
    }

    @Test("A button holding only an undescribed icon is reported", .publishingContext())
    func undescribedIconInButton() {
        _ = Button { Image(systemName: "star", description: "") }.markupString()
        #expect(warnings == [Button.missingNameWarning])
    }

    @Test("The warning says what to do")
    func warningText() {
        #expect(Button.missingNameWarning == """
        A Button has no text, so a screen reader has nothing to announce for it. \
        Give it a title, describe its icon, or name it with .aria(.label, "…").
        """)
    }

    @Test("A button named some other way is not reported", .publishingContext())
    func namedButtons() {
        _ = Button("", systemImage: "star").aria(.label, "Favourite").markupString()
        _ = Button().role(.close).markupString()
        _ = Button { Image(systemName: "star", description: "Favourite") }.markupString()
        _ = Button { Image("/images/go.png", description: "Go") }.markupString()
        _ = Button { Span("Next").class("visually-hidden") }.markupString()
        _ = Button("Go").markupString()
        _ = Button().customAttribute(name: "title", value: "Go").markupString()
        #expect(warnings.isEmpty)
    }

    @Test("The buttons Ignite draws for its own components are all named", .publishingContext())
    func componentButtonsAreNamed() {
        _ = Carousel { Slide { Text("One") }; Slide { Text("Two") } }.markupString()
        _ = Accordion { Item("Title") { Text("Body") } }.markupString()
        _ = NavigationBar(logo: "Site", items: { Link("A", target: "/a") }).markupString()
        _ = Dropdown("Menu") { Link("A", target: "/a") }.markupString()
        _ = Modal(id: "m") { Text("Body") } header: { Button().role(.close) }.markupString()
        #expect(warnings.isEmpty)
    }

    // MARK: - Text fields

    @Test("A field whose label is hidden keeps the label as its accessible name", .publishingContext())
    func hiddenLabelBecomesAriaLabel() {
        let output = Form { TextField("Email", prompt: "you@example.com") }.labelStyle(.hidden).markupString()
        #expect(output == """
        <form id="ig-form-2" class="row g-3"><div class="col-auto">\
        <input id="ig-field-1" type="text" placeholder="you@example.com" class="form-control" aria-label="Email" />\
        </div></form>
        """)
        #expect(warnings.isEmpty)
    }

    @Test("A hidden label is written as text, without its markup", .publishingContext())
    func hiddenLabelIsPlainText() {
        let field = TextField(Emphasis("Tom &amp; Jerry"), prompt: nil).labelStyle(.hidden)
        #expect(field.markupString()
            == #"<input id="ig-field-1" type="text" class="form-control" aria-label="Tom &amp; Jerry" />"#)
    }

    @Test("A field that names itself keeps its own name when its label is hidden", .publishingContext())
    func ownAriaLabelWins() {
        let field = TextField("Email", prompt: nil).labelStyle(.hidden).aria(.label, "Your address")
        #expect(field.markupString()
            == #"<input id="ig-field-1" type="text" class="form-control" aria-label="Your address" />"#)
    }

    @Test("A field with a visible label is written as before", .publishingContext())
    func visibleLabelsUnchanged() {
        #expect(TextField("Name", prompt: "Your name").markupString() == """
        <div class="form-floating">\
        <input id="ig-field-1" type="text" placeholder="Your name" class="form-control" />\
        <label for="ig-field-1">Name</label></div>
        """)
        #expect(TextField("Name", prompt: nil).labelStyle(.top).markupString() == """
        <div><label for="ig-field-2" class="form-label">Name</label>\
        <input id="ig-field-2" type="text" class="form-control" /></div>
        """)
        #expect(warnings.isEmpty)
    }

    @Test("A field with no label and no name is reported", .publishingContext())
    func unlabelledField() {
        _ = TextField("", prompt: "Search").markupString()
        #expect(warnings == [TextField.missingLabelWarning])
        #expect(TextField.missingLabelWarning == """
        A TextField has no label, so a screen reader has nothing to announce for it. \
        Give it a label – labelStyle(.hidden) keeps one off the page – or name it with .aria(.label, "…").
        """)
    }

    @Test("A field named with aria-label, or taken out of reach, is not reported", .publishingContext())
    func namedOrUnreachableFields() {
        _ = TextField("", prompt: "Search").aria(.label, "Search").markupString()
        _ = TextField("", prompt: nil).customAttribute(name: "tabindex", value: "-1").markupString()
        _ = TextField("", prompt: nil).aria(.hidden, "true").markupString()
        _ = SubscribeForm(.mailchimp(username: "u", uValue: "1", listID: "2")).markupString()
        #expect(warnings.isEmpty)
    }

    @Test("The email field of a subscribe form is named", .publishingContext())
    func subscribeFormFieldIsNamed() {
        let output = SubscribeForm(.buttondown("me")).markupString()
        #expect(output.contains(
            #"<input id="bd-email" placeholder="Email" type="text" name="email" class="form-control col" aria-label="Email" />"#))
    }

    // MARK: - Control groups

    @Test("A control group's label and help text are tied to the group", .publishingContext())
    func controlGroupLabelIsWired() {
        let output = ControlGroup("Amount") { Span("$"); Button("Pay") }.helpText("In dollars").markupString()
        #expect(output == """
        <div><label id="ig-group-1-label" class="form-label">Amount</label>\
        <div role="group" class="input-group" aria-labelledby="ig-group-1-label" aria-describedby="ig-group-1-help">\
        <span class="input-group-text">$</span><button type="button" class="btn">Pay</button></div>\
        <div id="ig-group-1-help" class="form-text">In dollars</div></div>
        """)
    }

    @Test("A control group with no label or help text is written as before", .publishingContext())
    func plainControlGroupUnchanged() {
        #expect(ControlGroup { Span("$"); Button("Pay") }.markupString() == """
        <div class="input-group"><span class="input-group-text">$</span>\
        <button type="button" class="btn">Pay</button></div>
        """)
    }

    @Test("A field in a control group that drops its label keeps the label as its name", .publishingContext())
    func controlGroupFieldKeepsName() {
        let output = ControlGroup { TextField("Amount", prompt: nil) }.labelStyle(.hidden).markupString()
        #expect(output == """
        <div class="input-group">\
        <input id="ig-field-1" type="text" class="form-control" aria-label="Amount" /></div>
        """)
        #expect(warnings.isEmpty)
    }

    // MARK: - Tables

    @Test("Table headers say they head a column", .publishingContext())
    func tableHeaderScope() {
        let output = Table {
            Row { Column { "a" }; Column { "b" } }
        } header: {
            "First"
            "Second"
        }.markupString()
        #expect(output == """
        <table class="table"><thead><tr><th scope="col">First</th><th scope="col">Second</th></tr></thead>\
        <tbody><tr><td colspan="1">a</td><td colspan="1">b</td></tr></tbody></table>
        """)
    }

    @Test("A table's filter field is named and says which table it controls", .publishingContext())
    func tableFilterIsNamed() {
        let output = Table(filterTitle: "Filter people") { Row { Column { "a" } } }.markupString()
        #expect(output == """
        <input class="form-control mb-2" type="text" placeholder="Filter people" \
        aria-label="Filter people" aria-controls="ig-table-1" \
        onkeyup="igniteFilterTable(this.value, 'ig-table-1')">\
        <table id="ig-table-1" class="table"><tbody><tr><td colspan="1">a</td></tr></tbody></table>
        """)
    }
}
