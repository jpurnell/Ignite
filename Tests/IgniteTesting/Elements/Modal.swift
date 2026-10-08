//
//  Modal.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `Modal` element.
@Suite("Modal Tests")
struct ModalTests {
    @Test("Show Modals", .publishingContext())
    func showModal() async throws {
        let element = Modal(id: "showModalId") {
            Text("Dismiss me by clicking on the backdrop.")
                .horizontalAlignment(.center)
                .font(.title3)
                .margin(.xLarge)
        }
        let output = element.markupString()

        #expect(output == """
        <div id="showModalId" tabindex="-1" class="modal fade" aria-hidden="true">\
        <div class="modal-dialog modal-dialog-centered">\
        <div class="modal-content"><div class="modal-body">\
        <h3 class="text-center m-5">Dismiss me by clicking on the backdrop.</h3>\
        </div></div></div></div>
        """)
    }

    @Test("Dismissing Modals", .publishingContext())
    func dismissModal() async throws {
        let element = Modal(id: "dismissModalId") {
            Section {
                Button().role(.close).onClick {
                    DismissModal(id: "dismissModalId")
                }
            }
            .horizontalAlignment(.trailing)

            Text("Dismiss me by clicking on the close button.")
                .horizontalAlignment(.center)
                .font(.title3)
                .margin(.xLarge)
        }
        let output = element.markupString()

        // The close button carries `aria-label`. It was written as `label`, which is not
        // an attribute, so the button had no accessible name.
        #expect(output == """
        <div id="dismissModalId" tabindex="-1" class="modal fade" aria-hidden="true">\
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content">\
        <div class="modal-body"><div class="text-end">\
        <button type="button" class="btn-close" aria-label="Close" onclick="\
        const modal = document.getElementById('dismissModalId');
        const modalInstance = bootstrap.Modal.getInstance(modal);
        if (modalInstance) { modalInstance.hide(); }"></button></div>\
        <h3 class="text-center m-5">Dismiss me by clicking on the close button.</h3></div></div></div></div>
        """)
    }

    @Test("Modal Size", .publishingContext(),
          arguments: Modal.Size.allCases)
    func checkModalSizes(sizeOption: Modal.Size) async throws {
        let element = Modal(id: "ModalId") {
            Text(markdown: "Modal with size")
                .horizontalAlignment(.center)
                .font(.title3)
                .margin(.xLarge)
        }
        .size(sizeOption)
        let output = element.markupString()

        if let htmlClass = sizeOption.htmlClass {
            #expect(output.contains("""
            <div class="modal-dialog \(htmlClass) modal-dialog-centered">
            """))
        } else {
            #expect(output.contains("""
            <div class="modal-dialog modal-dialog-centered">
            """))
        }
    }

    @Test("Modal Position", .publishingContext(), arguments: Modal.Position.allCases)
    func checkModalPosition(positionOption: Modal.Position) async throws {
        let element = Modal(id: "topModalId") {
            Text(markdown: "Modal with `Position`")
                .horizontalAlignment(.center)
                .font(.title3)
                .margin(.xLarge)
        }
            .modalPosition(positionOption)

        let output = element.markupString()
        if let htmlName = positionOption.htmlName {
            #expect(output.contains("""
            <div class="modal-dialog \(htmlName)">
            """))
        } else {
            #expect(output.contains("""
            <div class="modal-dialog">
            """))
        }

    }

    @Test("Modal Headers", .publishingContext())
    func modalHeaders() async throws {
        let element = Modal(id: "headerModalId") {
            Text("Body")
        } header: {
            Text("Header").font(.title5)

            Button().role(.close).onClick {
                DismissModal(id: "headerModalId")
            }
        }
        let output = element.markupString()

        #expect(output == """
        <div id="headerModalId" tabindex="-1" class="modal fade" \
        aria-labelledby="headerModalId-label" aria-hidden="true">\
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content">\
        <div id="headerModalId-label" class="modal-header"><h5>Header</h5>\
        <button type="button" class="btn-close" aria-label="Close" onclick="\
        const modal = document.getElementById('headerModalId');
        const modalInstance = bootstrap.Modal.getInstance(modal);
        if (modalInstance) { modalInstance.hide(); }"></button></div>\
        <div class="modal-body"><p>Body</p></div></div></div></div>
        """)
    }

    @Test("A modal with a header is labelled by that header", .publishingContext())
    func modalIsLabelledByItsHeader() async throws {
        let element = Modal(id: "settings") {
            Text("Body")
        } header: {
            Text("Settings").font(.title5)
        }

        #expect(element.markupString() == """
        <div id="settings" tabindex="-1" class="modal fade" aria-labelledby="settings-label" aria-hidden="true">\
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content">\
        <div id="settings-label" class="modal-header"><h5>Settings</h5></div>\
        <div class="modal-body"><p>Body</p></div></div></div></div>
        """)
    }

    @Test("A modal without a header claims no label", .publishingContext())
    func modalWithoutHeaderHasNoLabel() async throws {
        let element = Modal(id: "plain") {
            Text("Body")
        }

        #expect(element.markupString() == """
        <div id="plain" tabindex="-1" class="modal fade" aria-hidden="true">\
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content">\
        <div class="modal-body"><p>Body</p></div></div></div></div>
        """)
    }

    @Test("Two modals on one page are labelled by different elements", .publishingContext())
    func twoModalsDoNotShareALabel() async throws {
        let page = Section {
            Modal(id: "first") { Text("One") } header: { Text("First").font(.title5) }
            Modal(id: "second") { Text("Two") } header: { Text("Second").font(.title5) }
        }
        let output = page.markupString()

        let references = output.matches(of: #/aria-labelledby="([^"]+)"/#).map { String($0.1) }
        #expect(references == ["first-label", "second-label"])

        // Each referenced ID is declared exactly once on the page.
        for reference in references {
            #expect(output.matches(of: try Regex(#" id="\#(reference)""#)).count == 1)
        }
    }

    @Test("A modal with no ID of its own claims no label", .publishingContext())
    func modalWithoutIDHasNoLabel() async throws {
        let element = Modal(id: "") {
            Text("Body")
        } header: {
            Text("Untitled").font(.title5)
        }

        #expect(element.markupString() == """
        <div tabindex="-1" class="modal fade" aria-hidden="true">\
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content">\
        <div class="modal-header"><h5>Untitled</h5></div>\
        <div class="modal-body"><p>Body</p></div></div></div></div>
        """)
    }

    @Test("Modal Footers", .publishingContext())
    func modalFooters() async throws {
        let element = Modal(id: "footerModalId") {
            Text("Body")
        } footer: {
            Button("Close") {
                DismissModal(id: "footerModalId")
            }
            .role(.secondary)

            Button("Go") {
                // Do something
            }
            .role(.primary)
        }
        let output = element.markup()

        #expect(output.string == """
        <div id="footerModalId" tabindex="-1" class="modal fade" aria-hidden="true">\
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content">\
        <div class="modal-body"><p>Body</p></div><div class="modal-footer">\
        <button type="button" class="btn btn-secondary" onclick="\
        const modal = document.getElementById('footerModalId');
        const modalInstance = bootstrap.Modal.getInstance(modal);
        if (modalInstance) { modalInstance.hide(); }">\
        Close</button><button type="button" class="btn btn-primary">Go</button></div></div></div></div>
        """)
    }

    @Test("Modal Headers and Footers", .publishingContext())
    func modalHeadersAndFooters() async throws {
        let element = Modal(id: "headerAndFooterModalId") {
            Text("Body")
        } header: {
            Text("Header").font(.title5)

            Button().role(.close).onClick {
                DismissModal(id: "headerAndFooterModalId")
            }
        } footer: {
            Button("Close") {
                DismissModal(id: "headerAndFooterModalId")
            }
            .role(.secondary)

            Button("Go") {
                // Do something
            }
            .role(.primary)
        }
        let output = element.markup()

        #expect(output.string == """
        <div id="headerAndFooterModalId" tabindex="-1" class="modal fade" \
        aria-labelledby="headerAndFooterModalId-label" aria-hidden="true">\
        <div class="modal-dialog modal-dialog-centered">\
        <div class="modal-content"><div id="headerAndFooterModalId-label" class="modal-header"><h5>Header</h5>\
        <button type="button" class="btn-close" aria-label="Close" onclick="\
        const modal = document.getElementById('headerAndFooterModalId');
        const modalInstance = bootstrap.Modal.getInstance(modal);
        if (modalInstance) { modalInstance.hide(); }"></button></div>\
        <div class="modal-body"><p>Body</p></div><div class="modal-footer">\
        <button type="button" class="btn btn-secondary" onclick="\
        const modal = document.getElementById('headerAndFooterModalId');
        const modalInstance = bootstrap.Modal.getInstance(modal);
        if (modalInstance) { modalInstance.hide(); }">Close</button>\
        <button type="button" class="btn btn-primary">Go</button></div></div></div></div>
        """)
    }

    @Test("Modal Scrollable Content", .publishingContext())
    func modalScrollableContent() async throws {
        let element = Modal(id: "modal7") {
            Text(placeholderLength: 1000)
        } header: {
            Text("Long text")
                .font(.title5)
        }
        .size(.large)
        .scrollableContent(true)

        let output = element.markupString()
        #expect(output.contains("""
        <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
        """))
    }

    @Test("Modals Presentation Options", .publishingContext(), arguments: [
        ShowModal.Option.backdrop(dismissible: true), ShowModal.Option.backdrop(dismissible: false),
        ShowModal.Option.noBackdrop, ShowModal.Option.focus(true), ShowModal.Option.focus(false),
        ShowModal.Option.keyboard(true), ShowModal.Option.keyboard(false)])
    func checkModalPresentationOptions(option: ShowModal.Option) async throws {
        let element = Button("Show Modal") {
            ShowModal(id: "showModalId", options: [option])
        }
        let output = element.markupString()

        #expect(output.contains("""
        <button type="button" class="btn" onclick="const options = {
            \(option.htmlOption)
        };
        """))
    }

}
