//
//  CarouselIntervalSafetyTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for how `Carousel` converts its slide duration into Bootstrap's
/// millisecond interval when the duration is not a representable number.
@Suite("Carousel Interval Safety Tests")
class CarouselIntervalSafetyTests: IgniteTestSuite {
    private func carousel(slideDuration: Double) -> String {
        Carousel {
            Slide { Text("One") }
            Slide { Text("Two") }
        }
        .slideDuration(slideDuration)
        .markupString()
    }

    @Test("A representable duration is written in whole milliseconds", .publishingContext())
    func validDuration() async throws {
        #expect(carousel(slideDuration: 0.5).contains(#"data-bs-interval="500""#))
        #expect(carousel(slideDuration: 0.0019).contains(#"data-bs-interval="1""#))
    }

    @Test("An unrepresentable duration is rendered as no interval instead of trapping",
          .publishingContext(), arguments: [Double.nan, .infinity, -.infinity, 1e300, -1e300])
    func unrepresentableDuration(duration: Double) async throws {
        // No interval attribute at all is what a carousel with no slide duration renders.
        let output = carousel(slideDuration: duration)
        #expect(output.contains(#"data-bs-ride="carousel">"#))
        #expect(output.contains("data-bs-interval") == false)
    }
}
