//
// PublishingContext-ElementIDs.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension PublishingContext {
    /// Returns an ID for an element that needs one and was not given one: an accordion
    /// and its items, a carousel, a filterable table, a form and its fields.
    ///
    /// The ID is the element's kind followed by a number, such as `ig-accordion-3`. The
    /// number counts the IDs handed out on the page being rendered, in the order its
    /// elements are created, and starts again at 1 for each page. So an ID is unique
    /// within its page, a page that has not changed gets the same IDs on every build, and
    /// adding an element to one page does not renumber another.
    ///
    /// These IDs used to be random, which made every build of a site differ from the one
    /// before it and defeated anything that compares or caches the output.
    /// - Parameter kind: What the element is, as a lowercase word: `accordion`, `form`.
    /// - Returns: An ID that no other element on the page has been given.
    static func nextElementID(_ kind: String) -> String {
        "ig-\(kind)-\(nextElementNumber())"
    }

    /// Returns the number for the next generated ID on the page being rendered.
    ///
    /// Use ``nextElementID(_:)`` unless the ID has to be built around another, as an
    /// accordion item's is built around its accordion's.
    /// - Returns: A number no other generated ID on the page has used.
    static func nextElementNumber() -> Int {
        if let current {
            current.elementIDCount += 1
            return current.elementIDCount
        }

        // No publish is in progress – an element built by a test, or by a script. There is
        // no page to number within, so the count is kept for the process instead: still
        // unique, and still the same from one run to the next.
        return detachedElementIDCount.next()
    }

    /// Notes that a new page is about to be rendered, so that paths and generated IDs are
    /// worked out for it and not for the page before.
    /// - Parameter path: The page's path within the site, such as `/blog/post`. The empty
    /// string and `/` are the root.
    func beginPage(at path: String) {
        pageDirectoryDepth = Self.directoryDepth(of: path)
        elementIDCount = 0
    }

    /// How many element IDs have been handed out with no publish in progress.
    private static let detachedElementIDCount = LockedCounter()
}

/// A count that can be advanced from any thread.
// Justification: `count` is the only mutable state and every read or write of it holds `lock`.
private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    /// Advances the count and returns its new value.
    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}
