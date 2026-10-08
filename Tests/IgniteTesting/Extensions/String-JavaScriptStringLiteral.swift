//
//  String-JavaScriptStringLiteral.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `String-JavaScriptStringLiteral` extension.
@Suite("String-JavaScriptStringLiteral Tests")
struct StringJavaScriptStringLiteralTests {
    /// One string and the JavaScript literal it must be written as.
    struct Instance: Sendable {
        let input: String
        let expected: String
    }

    @Test("Strings with nothing to escape are only quoted", arguments: [
        Instance(input: "", expected: "''"),
        Instance(input: "a", expected: "'a'"),
        Instance(input: "side-bar_2", expected: "'side-bar_2'"),
        Instance(input: "Hello, World! 100% #1 (yes) [ok] {x} `tick` = + / ; :", expected:
            "'Hello, World! 100% #1 (yes) [ok] {x} `tick` = + / ; :'"),
        Instance(input: "caf\u{E9} \u{65E5}\u{672C}\u{8A9E} \u{1F600}", expected: "'caf\u{E9} \u{65E5}\u{672C}\u{8A9E} \u{1F600}'")
    ])
    func quotesPlainStrings(instance: Instance) {
        #expect(instance.input.javaScriptStringLiteral() == instance.expected)
    }

    @Test("Characters that end or corrupt a JavaScript string are escaped", arguments: [
        Instance(input: "'", expected: #"'\''"#),
        Instance(input: "it's", expected: #"'it\'s'"#),
        Instance(input: #"\"#, expected: #"'\\'"#),
        Instance(input: #"\'"#, expected: #"'\\\''"#),
        Instance(input: "a\nb", expected: #"'a\nb'"#),
        Instance(input: "a\rb", expected: #"'a\rb'"#),
        Instance(input: "a\r\nb", expected: #"'a\r\nb'"#),
        Instance(input: "a\tb", expected: #"'a\tb'"#),
        Instance(input: "a\u{2028}b\u{2029}c", expected: #"'a\u2028b\u2029c'"#),
        Instance(input: "a\u{0}b\u{8}c\u{1F}d\u{7F}e", expected: #"'a\u0000b\u0008c\u001Fd\u007Fe'"#)
    ])
    func escapesStringBreakers(instance: Instance) {
        #expect(instance.input.javaScriptStringLiteral() == instance.expected)
    }

    @Test("Characters that mean something to HTML are written as Unicode escapes", arguments: [
        Instance(input: #"say "hi""#, expected: #"'say \u0022hi\u0022'"#),
        Instance(input: "</script><script>alert(1)</script>", expected:
            #"'\u003C/script\u003E\u003Cscript\u003Ealert(1)\u003C/script\u003E'"#),
        Instance(input: "<!-- x -->", expected: #"'\u003C!-- x --\u003E'"#),
        Instance(input: "&#39;); evil(); //", expected: #"'\u0026#39;); evil(); //'"#),
        Instance(input: "Tom & Jerry &quot;", expected: #"'Tom \u0026 Jerry \u0026quot;'"#)
    ])
    func escapesHTMLSignificantCharacters(instance: Instance) {
        #expect(instance.input.javaScriptStringLiteral() == instance.expected)
    }

    @Test("The literal never contains a character that could end it or its attribute", arguments: [
        "a'b", #"a\b"#, #"a\'b"#, "a\nb", #"a"b"#, "a</script>b", "a&#39;b", "a\u{2028}b"
    ])
    func literalIsClosed(input: String) throws {
        let literal = input.javaScriptStringLiteral()
        let body = literal.dropFirst().dropLast()

        #expect(literal.hasPrefix("'") && literal.hasSuffix("'"))
        #expect(body.contains(where: { "\"<>&\n\r\u{2028}\u{2029}".contains($0) }) == false)

        // Every single quote and backslash left in the body is part of an escape:
        // removing the escapes whole must leave neither behind.
        let withoutEscapes = body
            .replacing(#"\\"#, with: "")
            .replacing(#"\'"#, with: "")
        #expect(withoutEscapes.contains("'") == false)
        #expect(withoutEscapes.replacing(#/\\(?:n|r|t|u[0-9A-F]{4})/#, with: "").contains(#"\"#) == false)
    }
}
