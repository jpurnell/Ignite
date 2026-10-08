//
// Animatable.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import OrderedCollections

/// A protocol that defines the core animation capabilities for Ignite's animation system.
protocol Animatable: Hashable, Sendable {}

extension Animatable {
    /// A short identifier derived from everything the animation does, used to name its
    /// CSS classes.
    ///
    /// Two animations that are the same share an identifier, and so share one set of CSS
    /// rules; two that differ in any way get different ones. The identifier used to be
    /// derived from the animation's type alone, so every transition on a site was given
    /// the same class and the rules of the last one registered applied to them all.
    var id: String {
        String(describing: self).truncatedHash
    }
}
