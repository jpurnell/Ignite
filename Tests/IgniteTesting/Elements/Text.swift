//
// Text.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Testing

@testable import Ignite

/// Tests for the `Text` element.
@Suite("Text Tests")
class TextTests: IgniteTestSuite {
    @Test("Simple String", .publishingContext())
    func simpleString() async throws {
        let element = Text("Hello")
        let output = element.markupString()
        #expect(output == "<p>Hello</p>")
    }

    @Test("Builder with Simple String", .publishingContext())
    func test_simpleBuilderString() async throws {
        let element = Text { "Hello" }
        let output = element.markupString()
        #expect(output == "<p>Hello</p>")
    }

    @Test("Builder with Complex String", .publishingContext())
    func complexBuilderString() {
        let element = Text {
            "Hello, "
            Emphasis("world")

            Strikethrough {
                " - "
                Strong {
                    "this "
                    Underline("is")
                    " a"
                }
                " test!"
            }
        }

        let output = element.markupString()

        #expect(output == """
        <p>Hello, <em>world</em><s> - <strong>this <u>is</u> a</strong> test!</s></p>
        """)
    }

    @Test("Custom Font", .publishingContext(), arguments: Font.Style.allCases)
    func customFont(font: Font.Style) async throws {
        let element = Text("Hello").font(font)
        let output = element.markupString()

        if FontStyle.classBasedStyles.contains(font), let sizeClass = font.sizeClass {
            // This applies a paragraph class rather than a different tag.
            #expect(output == "<p class=\"\(sizeClass)\">Hello</p>")
        } else {
            #expect(output == "<\(font.rawValue)>Hello</\(font.rawValue)>")
        }
    }

    @Test("Markdown", .publishingContext())
    func markdown() async throws {
        let element = Text(markdown: "*i*, **b**, and ***b&i***")
        let output = element.markupString()

        // The `&` is text, so it is written as `&amp;`. It was written bare, which
        // browsers tolerate here but would read as a character reference before `i;`.
        #expect(output == """
        <p><em>i</em>, <strong>b</strong>, and <em><strong>b&amp;i</strong></em></p>
        """)
    }

    @Test("Placeholder text is the same every time it is built", .publishingContext())
    func placeholderIsReproducible() async throws {
        let first = Text(placeholderLength: 60).markupString()
        let second = Text(placeholderLength: 60).markupString()

        #expect(first == second)
    }

    @Test("Placeholder text follows the generator it is given", .publishingContext())
    func placeholderFollowsGenerator() async throws {
        var first = SeededGenerator(seed: 7)
        var second = SeededGenerator(seed: 7)
        var other = SeededGenerator(seed: 8)

        let firstOutput = Text(placeholderLength: 60, using: &first).markupString()
        let secondOutput = Text(placeholderLength: 60, using: &second).markupString()
        let otherOutput = Text(placeholderLength: 60, using: &other).markupString()

        #expect(firstOutput == secondOutput)
        #expect(firstOutput != otherOutput)
        #expect(firstOutput.hasPrefix("<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. "))
    }

    @Test("Placeholder text has the number of words asked for", .publishingContext(), arguments: [1, 8, 9, 60])
    func placeholderWordCount(length: Int) async throws {
        let output = Text(placeholderLength: length).markupString()
        let words = output.split(separator: " ")

        #expect(words.count == length)
        #expect(output.hasSuffix(".</p>"))
    }

    @Test("Short placeholder text is the opening of lorem ipsum", .publishingContext())
    func shortPlaceholder() async throws {
        let output = Text(placeholderLength: 3).markupString()

        #expect(output == "<p>Lorem ipsum dolor.</p>")
    }

    @Test("Strikethrough", .publishingContext())
    func strikethrough() async throws {
        // Given
        let element = Text {
            Strikethrough {
                "There will be a few tickets available at the box office tonight."
            }
        }
        // When
        let output = element.markupString()
        // Then
        #expect(output == """
        <p><s>There will be a few tickets available at the box office tonight.</s></p>
        """)
    }
}
