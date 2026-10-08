//
//  Accordion.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `Accordion` element.
@Suite("Accordion Tests")
class AccordionTests: IgniteTestSuite {
    @Test("Renders a div tag of class accordion", .publishingContext())
    func outputs_div_with_class_accordion() async throws {
        let sut = Accordion {}
        let attributes = try #require(sut.markupString().htmlTagWithCloseTag("div")?.attributes)
        let classAttribute = try #require(attributes.htmlAttribute(named: "class"))
        #expect(classAttribute == "accordion")
    }

    @Test("Provides a Unique id", .publishingContext())
    func outputs_div_with_unique_id() async throws {
        let sut = Accordion {}

        let idattribute = try #require(sut.markupString().htmlTagWithCloseTag("div")?
            .attributes
            .htmlAttribute(named: "id")
        )

        // The ID is the first one generated on this page. It used to be `accordion`
        // followed by five random characters, which made every build differ.
        #expect(idattribute == "ig-accordion-1")
    }

    @Test("Two accordions on a page have different IDs", .publishingContext())
    func accordionsOnAPageHaveDifferentIDs() async throws {
        let first = try #require(Accordion {}.markupString().htmlAttribute(named: "id"))
        let second = try #require(Accordion {}.markupString().htmlAttribute(named: "id"))

        #expect(first == "ig-accordion-1")
        #expect(second == "ig-accordion-2")
    }

    @Test("Outputs Items Provided", .publishingContext(), arguments: [Accordion.OpenMode.all, .individual])
    func outputs_result_of_calling_render_on_each_item_provided(openMode: Accordion.OpenMode) throws {
        func items() -> [Item] {[
            Item("title 1", content: {}),
            Item("second title", content: { Text("hello") }),
            Item("titulo 3", content: { Image("imagename") })
        ]}

        let sut = Accordion(items).openMode(openMode)
        let output = sut.markupString()

        let accordionID = try #require(output.htmlTagWithCloseTag("div")?.attributes.htmlAttribute(named: "id"))

        // each item takes the next number on the page each time it is rendered,
        // so that part of the result will never match
        let deterministicOutput = output
            .clearingItemIDs()
            .clearingAccordionIDs()

        for item in items() {
            let itemoutput = item
                .assigned(to: accordionID, openMode: openMode)
                .markup()
                .string

            let expected = itemoutput
                .clearingItemIDs()
                .clearingAccordionIDs()

            #expect(deterministicOutput.contains(expected))
        }
    }

    @Test("Items Receive Accordion ID of parent Accordion", .publishingContext(), arguments: [Accordion.OpenMode.all, .individual])
    func provides_accordion_id_to_each_item_output(openMode: Accordion.OpenMode) throws {
        func items() -> [Item] {[
            Item("title 1", content: {}),
            Item("second title", content: { Text("hello") }),
            Item("titulo 3", content: { Image("imagename") })
        ]}

        let sut = Accordion(items).openMode(openMode)
        let output = sut.markupString()

        let accordionID = try #require(output.htmlTagWithCloseTag("div")?.attributes.htmlAttribute(named: "id"))

        let pattern = /ig-accordion-[0-9]+/
        #expect(output.matches(of: pattern).isEmpty == false)

        for match in output.matches(of: pattern) {
            #expect(String(match.0) == accordionID)
        }
    }
}

// MARK: - Helpers

private extension String {
    func clearingItemIDs() -> String {
        let toReplace = /-item-[0-9]+/
        return replacing(toReplace, with: "-----")
    }

    func clearingAccordionIDs() -> String {
        let toReplace = /ig-accordion-[0-9]+/
        return replacing(toReplace, with: "-----")
    }
}
