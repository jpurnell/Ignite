//
//  RoleClasses.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Testing

@testable import Ignite

/// Tests that a role only ever produces a class Bootstrap defines for that component.
///
/// Bootstrap defines its colored variants – `alert-*`, `text-bg-*`, `list-group-item-*`,
/// `btn-*`, `link-*` – for its eight theme colors. `.default`, `.none` and `.close` are not
/// among them, so they have no colored class to give.
@Suite("Role Classes Tests")
struct RoleClassesTests {
    /// The roles that are not one of Bootstrap's eight theme colors.
    static let uncoloredRoles: [Role] = [.default, .none, .close]

    @Test("Every role is either one of the eight theme colors or uncolored")
    func rolesAreAccountedFor() {
        #expect(Set(Role.standardRoles).union(Self.uncoloredRoles) == Set(Role.allCases))
        #expect(Role.standardRoles.map(\.themeColorName) == [
            "primary", "secondary", "success", "danger", "warning", "info", "light", "dark"
        ])
        #expect(Self.uncoloredRoles.map(\.themeColorName) == [nil, nil, nil])
    }

    // MARK: - Alert

    @Test("An alert with a theme color keeps its class", .publishingContext())
    func alertThemeColor() {
        #expect(Alert { "x" }.role(.danger).markupString() == #"<div class="alert alert-danger">x</div>"#)
    }

    @Test("An alert with an uncolored role has no role class", .publishingContext(), arguments: uncoloredRoles)
    func alertUncolored(role: Role) {
        #expect(Alert { "x" }.role(role).markupString() == #"<div class="alert">x</div>"#)
    }

    // MARK: - Badge

    @Test("A badge with a theme color keeps its classes", .publishingContext())
    func badgeThemeColor() {
        #expect(Badge("x").role(.info).markupString() == #"<span class="badge text-bg-info rounded-pill">x</span>"#)
        #expect(Badge("x").role(.info).badgeStyle(.subtle).markupString()
            == #"<span class="badge bg-info-subtle text-info-emphasis rounded-pill">x</span>"#)
        #expect(Badge("x").role(.info).badgeStyle(.subtleBordered).markupString() == """
        <span class="badge bg-info-subtle border border-info-subtle text-info-emphasis rounded-pill">x</span>
        """)
    }

    @Test("A badge with an uncolored role has no role classes", .publishingContext(), arguments: uncoloredRoles)
    func badgeUncolored(role: Role) {
        #expect(Badge("x").role(role).markupString() == #"<span class="badge rounded-pill">x</span>"#)
        #expect(Badge("x").role(role).badgeStyle(.subtle).markupString()
            == #"<span class="badge rounded-pill">x</span>"#)
        // `border` is a Bootstrap class in its own right, and is what makes this style bordered.
        #expect(Badge("x").role(role).badgeStyle(.subtleBordered).markupString()
            == #"<span class="badge border rounded-pill">x</span>"#)
    }

    // MARK: - ListItem

    @Test("A list item with a theme color keeps its class", .publishingContext())
    func listItemThemeColor() {
        #expect(ListItem { "x" }.role(.success).markupString() == #"<li class="list-group-item-success">x</li>"#)
    }

    @Test("A list item with an uncolored role has no role class", .publishingContext(), arguments: uncoloredRoles)
    func listItemUncolored(role: Role) {
        #expect(ListItem { "x" }.role(role).markupString() == "<li>x</li>")
    }

    // MARK: - Button

    @Test("A button with a theme color keeps its class", .publishingContext())
    func buttonThemeColor() {
        #expect(Button("x").role(.primary).markupString()
            == #"<button type="button" class="btn btn-primary">x</button>"#)
    }

    @Test("A button with no role or the none role has only the button class", .publishingContext(),
          arguments: [Role.default, .none])
    func buttonUncolored(role: Role) {
        #expect(Button("x").role(role).markupString() == #"<button type="button" class="btn">x</button>"#)
    }

    @Test("A close button uses Bootstrap's close class and is labelled for assistive technology",
          .publishingContext())
    func buttonClose() {
        #expect(Button().role(.close).markupString()
            == #"<button type="button" class="btn-close" aria-label="Close"></button>"#)
    }

    @Test("A close button has no size class, since Bootstrap defines none for it", .publishingContext())
    func closeButtonIgnoresSize() {
        for size in Button.Size.allCases {
            #expect(Button().role(.close).buttonSize(size).markupString()
                == #"<button type="button" class="btn-close" aria-label="Close"></button>"#)
        }
    }

    @Test("A sized button with a theme color keeps Bootstrap's base, size and color classes",
          .publishingContext())
    func sizedThemeButtonIsUnchanged() {
        #expect(Button("x").role(.danger).buttonSize(.large).markupString()
            == #"<button type="button" class="btn btn-lg btn-danger">x</button>"#)
    }

    @Test("Only a close button is given a label", .publishingContext())
    func onlyCloseButtonIsLabelled() {
        for role in Role.allCases where role != .close {
            #expect(Button.aria(forRole: role) == nil)
        }
        #expect(Button.aria(forRole: .close) == Attribute(name: "aria-label", value: "Close"))
    }

    // MARK: - Link

    @Test("A link with a theme color keeps its class", .publishingContext())
    func linkThemeColor() {
        #expect(Link("x", target: "/a").role(.danger).markupString()
            == #"<a href="/a/" class="link-danger">x</a>"#)
    }

    @Test("A link with the none role keeps Ignite's plain link class", .publishingContext())
    func linkNone() {
        #expect(Link("x", target: "/a").role(.none).markupString() == #"<a href="/a/" class="link-plain">x</a>"#)
    }

    @Test("A link with the close role has no role class", .publishingContext())
    func linkClose() {
        #expect(Link("x", target: "/a").role(.close).markupString() == #"<a href="/a/">x</a>"#)
    }

    @Test("A link styled as a button follows the button rule", .publishingContext())
    func linkButton() {
        #expect(Link("x", target: "/a").linkStyle(.button).role(.none).markupString()
            == #"<a href="/a/" class="btn">x</a>"#)
        #expect(Link("x", target: "/a").linkStyle(.button).role(.success).markupString()
            == #"<a href="/a/" class="btn btn-success">x</a>"#)
    }
}
