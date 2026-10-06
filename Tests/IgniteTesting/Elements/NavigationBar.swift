//
// NavigationBar.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Testing

@testable import Ignite

/// Tests for the `NavigationBar` element.
@Suite("Navigation Bar Tests")
class NavigationBarTests: IgniteTestSuite {
    @Test("Root Tag is Header", .publishingContext())
    func headerTag() async throws {
        let element = NavigationBar()
        let output = element.markupString()

        let header = try #require(output.htmlTagWithCloseTag("header"))
        #expect(header.attributes == "")
        #expect(header.contents == """
        <nav class="navbar navbar-expand-md">\
        <div class="container flex-wrap flex-lg-nowrap"></div>\
        </nav>
        """)
    }

    @Test("Has Nav Tag Inside Header", .publishingContext())
    func navTag() async throws {
        let element = NavigationBar()
        let output = element.markupString()

        let header = try #require(output
            .htmlTagWithCloseTag("header"))

        let nav = try #require(header.contents.htmlTagWithCloseTag("nav"))
        #expect(nav.attributes == #" class="navbar navbar-expand-md""#)
        #expect(nav.contents == #"<div class="container flex-wrap flex-lg-nowrap"></div>"#)
    }

    @Test("Nav Tag Class Is navbar and navbar-expand-md", .publishingContext())
    func navTagClass() async throws {
        let element = NavigationBar()
        let output = element.markupString()

        let navClasses = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.attributes
            .htmlAttribute(named: "class")?
            .components(separatedBy: " ")
        )

        let expected = ["navbar", "navbar-expand-md"]
        #expect(navClasses == expected)
    }

    @Test("Nav Tag Class data-bs-theme is blank if style is default", .publishingContext())
    func navTagDefaultTheme() async throws {
        let element = NavigationBar()
        let output = element.markupString()

        let navAttributes = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.attributes
        )

        #expect(navAttributes.htmlAttribute(named: "data-bs-theme") == nil)
    }

    @Test("Nav Tag Class data-bs-theme is dark if style is dark", .publishingContext())
    func navTagDarkTheme() async throws {
        let element = NavigationBar().navigationBarStyle(.dark)
        let output = element.markupString()

        let theme = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.attributes
            .htmlAttribute(named: "data-bs-theme")
        )

        let expected = "dark"
        #expect(theme == expected)
    }

    @Test("Nav Tag Class data-bs-theme is light if style is light", .publishingContext())
    func navTagLightTheme() async throws {
        let element = NavigationBar().navigationBarStyle(.light)
        let output = element.markupString()

        let theme = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.attributes
            .htmlAttribute(named: "data-bs-theme")
        )

        let expected = "light"
        #expect(theme == expected)
    }

    @Test("Has Div Tag Inside if given width", .publishingContext(), arguments: [
        NavigationBar.Width.viewport,
        .count(2),
        .count(10)
    ])
    func divTagForColumnWidth(width: NavigationBar.Width) async throws {
        let element = NavigationBar().width(width)
        let output = element.markupString()

        let navContents = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
        )

        let div = try #require(navContents.htmlTagWithCloseTag("div"))
        let expectedClasses = switch width {
        case .viewport: "container-fluid col flex-wrap flex-lg-nowrap"
        case .count(let columns): "container col-md-\(columns) flex-wrap flex-lg-nowrap"
        }
        #expect(div.attributes == " class=\"\(expectedClasses)\"")
        #expect(div.contents == "")
    }

    @Test("Div Tag Class contains column count if given column width", .publishingContext(), arguments: [0, 3, 7])
    func divTagClassBeginsWithColumnCount(columns: Int) async throws {
        let element = NavigationBar().width(.count(columns))
        let output = element.markupString()

        let divClasses = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
            .htmlTagWithCloseTag("div")?.attributes
            .htmlAttribute(named: "class")?
            .components(separatedBy: " ")
        )

        let expected = "col-md-\(columns)"
        #expect(divClasses.contains(expected))
    }

    @Test("Div Tag Class contains `container` if given column width", .publishingContext(), arguments: [
        NavigationBar.Width.count(2),
        .count(10)
    ])
    func divTagClassEndsWithContainer(width: NavigationBar.Width) async throws {
        let element = NavigationBar().width(width)
        let output = element.markupString()

        let divClasses = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
            .htmlTagWithCloseTag("div")?.attributes
            .htmlAttribute(named: "class")?
            .components(separatedBy: " ")
        )

        let expected = "container"
        #expect(divClasses.contains(expected))
    }

    @Test("Div Tag Class is as expected if given viewport width", .publishingContext())
    func divTagClassIsFluid() async throws {
        let element = NavigationBar().width(.viewport)
        let output = element.markupString()

        let divClasses = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
            .htmlTagWithCloseTag("div")?.attributes
            .htmlAttribute(named: "class")?
            .components(separatedBy: " ")
        )

        let expected = "container-fluid col flex-wrap flex-lg-nowrap".components(separatedBy: " ")
        #expect(divClasses == expected)
    }

    @Test("Div Tag contains logo if given logo", .publishingContext())
    func divTagContainsLogo() async throws {
        let logoImage = Image("/images/logo.png")
        let element = NavigationBar(logo: logoImage)
        let output = element.markupString()

        let divContents = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
            .htmlTagWithCloseTag("div")?.contents
        )

        #expect(logoImage.markupString() == #"<img src="/images/logo.png" alt="" />"#)
        #expect(divContents == """
        <div class="me-2 me-md-auto">\
        <a href="/" class="d-inline-flex align-items-center navbar-brand">\
        <img src="/images/logo.png" alt="" />\
        </a>
        """)
    }

    @Test("Div contains render toggle button if items is not empty", .publishingContext())
    func divTagContainsToggleButton() async throws {
        let target = try #require(URL(string: "1"))
        let element = NavigationBar(logo: Image("somepath")) {
            Link("Link 1", target: target)
        }
        let output = element.markupString()

        let navContents = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents)

        #expect(navContents.contains("""
        <button type="button" \
        class="navbar-toggler btn" \
        data-bs-toggle="collapse" \
        data-bs-target="#navbarCollapse" aria-controls="navbarCollapse" \
        aria-expanded="false" aria-label="Toggle navigation">\
        <span class="navbar-toggler-icon"></span></button>
        """))
    }

    @Test("Div Tag contains unordered list if items is not nil", .publishingContext())
    func divTagContainsUL() async throws {
        let item = try Link("Link 1", target: #require(URL(string: "1")))
        let element = NavigationBar(logo: Image("somepath")) {
            item
        }
        let output = element.markupString()

        let divContents = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents)

        let list = try #require(divContents.htmlTagWithCloseTag("ul"))
        #expect(list.attributes == #" class="navbar-nav mb-2 mb-md-0 col justify-content-end""#)
        #expect(list.contents == #"<li class="nav-item"><a href="1/" class="nav-link text-nowrap">Link 1</a></li>"#)
    }

    @Test("Unordered List contains trailing alignment if set", .publishingContext())
    func ulTagClassContainCenterAignmentIfGiven() async throws {
        let item = try Link("Link 1", target: #require(URL(string: "1")))
        let element = NavigationBar(logo: Image("somepath")) {
            item
        }
        .navigationItemAlignment(.center)
        let output = element.markupString()

        let ulClasses = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
            .htmlTagWithCloseTag("ul")?.attributes
            .htmlAttribute(named: "class"))

        let expected = "justify-content-center"
        #expect(ulClasses.contains(expected))
    }

    @Test("Unordered List contains trailing alignment if set", .publishingContext())
    func ulTagClassContainTrailingAignmentIfGiven() async throws {
        let item = try Link("Link 1", target: #require(URL(string: "1")))
        let element = NavigationBar(logo: Image("somepath")) {
            item
        }
        .navigationItemAlignment(.trailing)
        let output = element.markupString()

        let ulClasses = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
            .htmlTagWithCloseTag("ul")?.attributes
            .htmlAttribute(named: "class"))

        let expected = "justify-content-end"
        #expect(ulClasses.contains(expected))
    }

    @Test("UL Tag contains rendered output of navigation item", .publishingContext())
    func divTagContainsRenderedItem() async throws {
        let item = try Link("Link 1", target: #require(URL(string: "1")))
        let element = NavigationBar(logo: Image("somepath")) {
            item
        }
        let output = element.markupString()

        let ulContents = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
            .htmlTagWithCloseTag("ul")?.contents)

        let expectedLink = item
            .class("nav-link text-nowrap")
            .markup()
            .string
        let expectedNavItem = "<li class=\"nav-item\">\(expectedLink)</li>"

        #expect(ulContents.contains(expectedNavItem))
    }

    @Test("UL Tag contains rendered output of navigation items", .publishingContext())
    func divTagContainsRenderedItems() async throws {
        let item1 = try Link("Link 1", target: #require(URL(string: "1")))
        let item2 = try Link("Link 2", target: #require(URL(string: "2")))
        let element = NavigationBar(logo: Image("somepath")) {
            item1
            item2
        }
        let output = element.markupString()

        let ulContents = try #require(output
            .htmlTagWithCloseTag("header")?.contents
            .htmlTagWithCloseTag("nav")?.contents
            .htmlTagWithCloseTag("ul")?.contents)

        let expectedLink1 = item1
            .class("nav-link text-nowrap")
            .markup()
            .string
        let expectedNavItem1 = "<li class=\"nav-item\">\(expectedLink1)</li>"

        let expectedLink2 = item2
            .class("nav-link text-nowrap")
            .markup()
            .string
        let expectedNavItem2 = "<li class=\"nav-item\">\(expectedLink2)</li>"

        #expect(ulContents.contains(expectedNavItem1))
        #expect(ulContents.contains(expectedNavItem2))
    }
}
