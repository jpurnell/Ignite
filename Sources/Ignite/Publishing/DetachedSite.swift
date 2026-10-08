//
// DetachedSite.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// The site of a publishing context that belongs to no publish.
///
/// Elements read their site's settings from the publishing context as they render. When
/// something is rendered with no publish in progress – from a unit test of your own, or a
/// script that calls `markup()` directly – there is no site to read, and this one answers
/// instead: it has no name, no author and no title suffix, every setting `Site` gives a
/// default for keeps that default, and its address is in the reserved `.invalid` domain
/// so that nothing rendered against it can be mistaken for a real page.
struct DetachedSite: Site {
    var name = ""
    var url = URL(static: "https://detached.invalid")
    var homePage = DetachedPage()
    var layout = EmptyLayout()
}

/// The home page of a ``DetachedSite``, which has no content.
struct DetachedPage: StaticPage {
    var title = ""

    var body: some HTML {
        EmptyHTML()
    }
}
