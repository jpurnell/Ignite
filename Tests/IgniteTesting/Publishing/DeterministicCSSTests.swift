//
//  DeterministicCSSTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A style with a different color under each of four separate conditions.
private struct OrderedRulesStyle: Style {
    func style(content: StyledHTML, environment: EnvironmentConditions) -> StyledHTML {
        if environment.colorScheme == .dark {
            content.style(.color, "white")
        } else if environment.orientation == .landscape {
            content.style(.color, "blue")
        } else if environment.motion == .reduced {
            content.style(.color, "green")
        } else if environment.contrast == .high {
            content.style(.color, "black")
        } else {
            content.style(.color, "red")
        }
    }
}

/// Tests that generated CSS comes out in one fixed order.
///
/// The order of rules decides which one wins when two apply, and the order of the
/// collections these rules were held in changed from one run of the build to the next.
@Suite("Deterministic CSS Tests")
struct DeterministicCSSTests {
    @Test("A style's rules are written in the order its conditions are defined", .publishingContext())
    func styleRulesHaveAFixedOrder() {
        let css = StyleManager().generateCSS(style: OrderedRulesStyle(), themes: [])

        #expect(css == """
        .ordered-rules-style {
            color: red;
        }

        @media (prefers-contrast: more) {
            .ordered-rules-style {
            color: black;
        }
        }

        @media (prefers-reduced-motion: reduce) {
            .ordered-rules-style {
            color: green;
        }
        }

        @media (orientation: landscape) {
            .ordered-rules-style {
            color: blue;
        }
        }

        @media (prefers-color-scheme: dark) {
            .ordered-rules-style {
            color: white;
        }
        }
        """)
    }

    @Test("An appear transition's declarations are written in a fixed order", .publishingContext())
    func transitionDeclarationsHaveAFixedOrder() {
        let transition = Transition.fadeIn
            .combined(with: Transition.scale().data)
            .combined(with: Transition.color(.red).data)
            .combined(with: Transition.blur(radius: 4).data)
        let css = AnimationClassGenerator(trigger: .appear, animation: transition).build()

        // The initial value of each property in the order the transition lists them, then
        // the transition itself.
        #expect(css.hasPrefix("""
        .animation-\(transition.id) {
                opacity: 0;
                transform: scale(0.8);
                color: inherit;
                filter: blur(0px);
                transition: opacity TIMING, transform TIMING, color TIMING, filter TIMING;
            }
        """.replacing("TIMING", with: "0.35s cubic-bezier(0.4, 1.0, 0.0, 1.0)")))
    }
}
