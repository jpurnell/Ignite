//
//  TransitionModifier.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Testing

@testable import Ignite

/// Tests for the `TransitionModifier`.
@Suite("TransitionModifier Tests")
class TransitionModifierTests: IgniteTestSuite {
    @Test("Different transitions get different classes, and the same transition the same class", .publishingContext())
    func classIsDerivedFromTheTransition() async throws {
        let fade = Text("A").transition(.fadeIn, on: .appear).markupString()
        let fadeAgain = Text("B").transition(.fadeIn, on: .appear).markupString()
        let slide = Text("C").transition(.slideIn(from: .top), on: .appear).markupString()

        let fadeID = try #require(firstAnimationID(in: fade))
        #expect(firstAnimationID(in: fadeAgain) == fadeID)
        #expect(firstAnimationID(in: slide) != fadeID)

        // Each class has its own rule, so one transition's CSS cannot replace another's.
        #expect(Transition.fadeIn.id != Transition.slideIn(from: .top).id)
        #expect(Transition.fadeIn.id != Transition.fadeOut.id)
        #expect(Transition.fadeIn.id == Transition.fadeIn.id)
        #expect(Animation().id != Transition().id)
    }

    @Test("Hover transition adds hover class and 3D transform style", .publishingContext())
    func hoverTransitionAddsHoverClassAndStyle() async throws {
        let transition = Transition.scale()
        let element = Text("Hello").transition(transition, on: .hover)
        let output = element.markupString()

        let hoverID = firstHoverAnimationID(in: output)

        #expect(hoverID == transition.id)
        #expect(output.contains(#"style="transform-style: preserve-3d""#))
        #expect(output.contains("Hello"))
        #expect(!output.contains(#"onclick="igniteToggleClickAnimation(this)""#))
        #expect(!output.contains(#"class="click-"#))
    }

    @Test("Click transition adds click handler and paired class names", .publishingContext())
    func clickTransitionAddsClickHandler() async throws {
        let transition = Transition.scale()
        let element = Text("Hello").transition(transition, on: .click)
        let output = element.markupString()

        let animationID = firstAnimationID(in: output)
        let clickID = firstClickID(in: output)

        #expect(animationID == transition.id)
        #expect(clickID == transition.id)
        #expect(output.contains(#"onclick="igniteToggleClickAnimation(this)""#))
        #expect(output.contains("Hello"))
    }

    @Test("Appear transition adds animation class without click or hover scaffolding", .publishingContext())
    func appearTransitionAddsAppearClassOnly() async throws {
        let transition = Transition.scale()
        let element = Text("Hello").transition(transition, on: .appear)
        let output = element.markupString()

        let appearID = firstAnimationID(in: output)

        #expect(appearID == transition.id)
        #expect(output.contains("Hello"))
        #expect(!output.contains("-hover"))
        #expect(!output.contains(#"onclick="igniteToggleClickAnimation(this)""#))
        #expect(!output.contains(#"class="click-"#))
    }

    private func firstHoverAnimationID(in source: String) -> String? {
        source.firstMatch(of: /class="[^"]*animation-([A-Za-z0-9]{5})-hover[^"]*"/).map { String($0.1) }
    }

    private func firstAnimationID(in source: String) -> String? {
        source.firstMatch(of: /class="[^"]*animation-([A-Za-z0-9]{5})[^"]*"/).map { String($0.1) }
    }

    private func firstClickID(in source: String) -> String? {
        source.firstMatch(of: /class="[^"]*click-([A-Za-z0-9]{5})[^"]*"/).map { String($0.1) }
    }
}
