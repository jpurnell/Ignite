//
//  ActionJavaScriptEscaping.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Every action that writes a Swift string into JavaScript writes it as a string literal
/// the string cannot end early, and every event attribute holds its JavaScript without
/// the JavaScript being able to end the attribute.
@Suite("Action JavaScript escaping Tests")
class ActionJavaScriptEscapingTests: IgniteTestSuite {
    /// An ID that closes a single-quoted string, escapes a quote, breaks the line,
    /// closes a script element, closes an attribute and names an HTML entity.
    private static let hostile = "a'b\\c\nd</script>e\"f&#39;g"

    /// `hostile` as the one JavaScript string literal it must become.
    private static let hostileLiteral = #"'a\'b\\c\nd\u003C/script\u003Ee\u0022f\u0026#39;g'"#

    @Test("ToggleElementVisibility keeps its ID inside one string literal", .publishingContext())
    func toggleElementVisibility() {
        #expect(ToggleElementVisibility(Self.hostile).compile()
            == "document.getElementById(\(Self.hostileLiteral)).classList.toggle('d-none')")
    }

    @Test("ShowElement keeps its ID inside one string literal", .publishingContext())
    func showElement() {
        #expect(ShowElement(Self.hostile).compile()
            == "document.getElementById(\(Self.hostileLiteral)).classList.remove('d-none')")
    }

    @Test("HideElement keeps its ID inside one string literal", .publishingContext())
    func hideElement() {
        #expect(HideElement(Self.hostile).compile()
            == "document.getElementById(\(Self.hostileLiteral)).classList.add('d-none')")
    }

    @Test("DismissModal keeps its ID inside one string literal", .publishingContext())
    func dismissModal() {
        #expect(DismissModal(id: Self.hostile).compile() == """
        const modal = document.getElementById(\(Self.hostileLiteral));
        const modalInstance = bootstrap.Modal.getInstance(modal);
        if (modalInstance) { modalInstance.hide(); }
        """)
    }

    @Test("ShowModal keeps its ID inside one string literal", .publishingContext())
    func showModal() {
        #expect(ShowModal(id: Self.hostile).compile() == """
        const options = {
            \n\
        };
        const modal = new bootstrap.Modal(document.getElementById(\(Self.hostileLiteral)), options);
        modal.show();
        """)
    }

    @Test("ShowAlert keeps its message inside one string literal", .publishingContext())
    func showAlert() {
        #expect(ShowAlert(message: Self.hostile).compile() == "alert(\(Self.hostileLiteral))")
    }

    @Test("Actions given ordinary IDs compile as they always have", .publishingContext())
    func ordinaryIDsAreUnchanged() {
        #expect(ToggleElementVisibility("side-bar_2").compile()
            == "document.getElementById('side-bar_2').classList.toggle('d-none')")
        #expect(ShowElement("side-bar_2").compile()
            == "document.getElementById('side-bar_2').classList.remove('d-none')")
        #expect(HideElement("side-bar_2").compile()
            == "document.getElementById('side-bar_2').classList.add('d-none')")
        #expect(DismissModal(id: "side-bar_2").compile() == """
        const modal = document.getElementById('side-bar_2');
        const modalInstance = bootstrap.Modal.getInstance(modal);
        if (modalInstance) { modalInstance.hide(); }
        """)
        #expect(ShowModal(id: "side-bar_2", options: [.backdrop(dismissible: false), .keyboard(false)]).compile() == """
        const options = {
            backdrop: 'static',
        \tkeyboard: false
        };
        const modal = new bootstrap.Modal(document.getElementById('side-bar_2'), options);
        modal.show();
        """)
        #expect(ShowAlert(message: "It's 100% done.").compile() == #"alert('It\'s 100% done.')"#)
        #expect(SwitchTheme(.dark).compile() == "igniteSwitchTheme('dark');")
    }

    @Test("CustomAction passes hand-written JavaScript through as written", .publishingContext(), arguments: [
        "igniteToggleClickAnimation(this)",
        "document.title = 'Hello'",
        #"console.log("a" + 'b')"#,
        "if (a && b < c) { go() }"
    ])
    func customActionIsNotRewritten(code: String) {
        #expect(CustomAction(code).compile() == code)
    }

    @Test("An event attribute cannot be ended by its JavaScript", .publishingContext())
    func eventAttributeEscapesDoubleQuotes() {
        let element = Tag("div") {}
            .onClick { CustomAction(#"console.log("a" + 'b')"#) }

        #expect(element.markupString() == """
        <div onclick="console.log(&quot;a&quot; + 'b')"></div>
        """)
    }

    @Test("An event attribute holds a hostile ID as one string literal", .publishingContext())
    func eventAttributeWithHostileID() {
        let element = Tag("div") {}
            .onClick { ToggleElementVisibility(Self.hostile) }

        #expect(element.markupString() == """
        <div onclick="document.getElementById(\(Self.hostileLiteral)).classList.toggle('d-none')"></div>
        """)
    }

    @Test("Hover effect values are written as string literals", .publishingContext())
    func hoverEffectValues() {
        let element = Text("Hello").hoverEffect { effect in
            effect.style(.fontFamily, "'Gill Sans', sans-serif")
        }

        #expect(element.markupString() == #"""
        <p onmouseover="this.unhoveredStyle = this.style.cssText;
        this.style.fontFamily = '\'Gill Sans\', sans-serif'" onmouseout="this.style.cssText = this.unhoveredStyle;">Hello</p>
        """#)
    }

    @Test("Google Analytics writes its measurement ID as one string literal", .publishingContext())
    func googleAnalyticsMeasurementID() {
        let output = Analytics(.googleAnalytics(measurementID: "G-1'); alert(1); ('")).markupString()

        #expect(output.contains(#"gtag('config', 'G-1\'); alert(1); (\'');"#))
        #expect(Analytics(.googleAnalytics(measurementID: "G-ABC123")).markupString().contains("gtag('config', 'G-ABC123');"))
    }
}
