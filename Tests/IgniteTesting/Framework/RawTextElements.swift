//
// RawTextElements.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

private struct RawTextTestStyle: Style {
    func style(content: StyledHTML, environment: EnvironmentConditions) -> StyledHTML {
        content.style(.color, "red")
    }
}

/// Tests that the content of a `<style>` or `<script>` element cannot end the element.
///
/// Nothing is escaped inside these elements – a browser reads their content as it is,
/// up to the first `</style` or `</script` – so a closing tag in the content is written
/// in a form CSS and JavaScript read as the same characters and HTML does not read as
/// a tag.
@Suite("Raw Text Element Tests")
class RawTextElementTests: IgniteTestSuite {
    // MARK: - Script

    @Test("JavaScript without a closing tag in it is written as given", .publishingContext(), arguments: [
        "var a = 1;",
        "if (a < b && c > d) { x = '<p>text</p>'; }",
        "const tag = 'script'; // </ script> is not a closing tag",
        "let s = \"<style>\";",
        "a <!-- an HTML-style comment\nb();",
        "x = '<script>';"
    ])
    func ordinaryScript(code: String) {
        #expect(Script(code: code).markupString() == "<script>\(code)</script>")
    }

    @Test("A closing script tag inside JavaScript cannot end the element", .publishingContext(), arguments: [
        ("var a = '</script><b>';", #"var a = '<\/script><b>';"#),
        ("var a = '</SCRIPT>';", #"var a = '<\/SCRIPT>';"#),
        ("var a = '</ScRiPt >';", #"var a = '<\/ScRiPt >';"#),
        ("a('</script>'); b('</script>');", #"a('<\/script>'); b('<\/script>');"#),
        ("var a = '</scripts>';", #"var a = '<\/scripts>';"#)
    ])
    func closingScriptTag(code: String, expected: String) {
        #expect(Script(code: code).markupString() == "<script>\(expected)</script>")
    }

    @Test("An opening script tag after a comment opener cannot keep the element open", .publishingContext(),
          arguments: [
        ("var a = '<!--<script>';", #"var a = '<!--\x3Cscript>';"#),
        ("var a = '<!-- <SCRIPT type=x>';", #"var a = '<!-- \x3CSCRIPT type=x>';"#),
        ("a = '<!--'; b = '<script/>';", #"a = '<!--'; b = '\x3Cscript/>';"#),
        // Once the comment is closed, an opening tag is harmless again.
        ("a = '<!-- -->'; b = '<script>';", "a = '<!-- -->'; b = '<script>';"),
        // `<scripts` is not `<script`.
        ("a = '<!--<scripts>';", "a = '<!--<scripts>';")
    ])
    func openingScriptTagInComment(code: String, expected: String) {
        #expect(Script(code: code).markupString() == "<script>\(expected)</script>")
    }

    @Test("A script keeps its attributes", .publishingContext())
    func scriptAttributes() {
        #expect(Script(code: "a('</script>')").type(value: "module").markupString()
            == #"<script type="module">a('<\/script>')</script>"#)
    }

    // MARK: - Style

    @Test("A selector that contains a closing style tag cannot end the element", .publishingContext())
    func closingStyleTag() {
        let output = MetaStyle("a[title=\"</style><script>alert(1)</script>\"]", style: RawTextTestStyle())
            .markupString()
        #expect(output.hasPrefix("<style>"))
        #expect(output.hasSuffix("</style>"))
        let content = String(output.dropFirst("<style>".count).dropLast("</style>".count))
        #expect(content.contains(#"a[title="<\/style><script>alert(1)</script>"]"#))
        #expect(content.lowercased().contains("</style") == false)
    }

    @Test("CSS without a closing tag in it is written as given", arguments: [
        "a { color: red; }",
        "a > b { content: '<p>'; }",
        "a::after { content: '</ style>'; }",
        "a { background: url(\"a/b.png\"); }"
    ])
    func ordinaryStyle(css: String) {
        #expect(RawTextElement.style.neutralizing(css) == css)
    }

    @Test("A closing style tag in CSS is escaped whatever its case", arguments: [
        ("a::after { content: '</style>'; }", #"a::after { content: '<\/style>'; }"#),
        ("a::after { content: '</STYLE >'; }", #"a::after { content: '<\/STYLE >'; }"#),
        ("</style></Style>", #"<\/style><\/Style>"#)
    ])
    func closingStyleTagInCSS(css: String, expected: String) {
        #expect(RawTextElement.style.neutralizing(css) == expected)
    }

    @Test("Each element is only concerned with its own closing tag")
    func elementsAreIndependent() {
        #expect(RawTextElement.style.neutralizing("</script>") == "</script>")
        #expect(RawTextElement.script.neutralizing("</style>") == "</style>")
    }

    @Test("Neutralized content is neutral: doing it again changes nothing", arguments: [
        "var a = '</script>';", "a = '<!--<script>';", "</style>"
    ])
    func idempotent(content: String) {
        for element in [RawTextElement.script, .style] {
            let once = element.neutralizing(content)
            #expect(element.neutralizing(once) == once)
        }
    }

    @Test("An element is written with its attributes and its neutralized content")
    func elementMarkup() {
        #expect(RawTextElement.style.markup(content: "a{}").string == "<style>a{}</style>")
        #expect(RawTextElement.script.markup(content: "a('</script>')").string
            == #"<script>a('<\/script>')</script>"#)
    }
}
