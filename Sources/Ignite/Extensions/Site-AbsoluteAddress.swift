//
// Site-AbsoluteAddress.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension Site {
    /// Turns a reference to something on this site into an absolute address.
    ///
    /// Sharing metadata, feeds and structured data are read by crawlers and feed readers
    /// away from the page they came from, so an address in them has to stand on its own.
    /// This holds whatever `useRelativePaths` says, which is about the page's own links.
    ///
    /// - An address that already has a scheme is returned as it is.
    /// - A protocol-relative address (`//cdn.example.com/a.png`) is given the scheme of
    ///   the site's own address.
    /// - A path, with or without a leading `/`, is taken from the root of the site and
    ///   appended to the site's address – including its path, for a site deployed in a
    ///   subdirectory.
    /// - Parameter reference: The address or path as the author wrote it.
    /// - Returns: An absolute address, or the empty string for an empty reference.
    func absoluteAddress(for reference: String) -> String {
        guard reference.isEmpty == false else { return reference }

        if reference.hasPrefix("//") {
            return "\(url.scheme ?? "https"):\(reference)"
        }

        if let scheme = URL(string: reference)?.scheme, scheme.isEmpty == false {
            return reference
        }

        var base = url.absoluteString
        while base.hasSuffix("/") {
            base.removeLast()
        }

        return reference.hasPrefix("/") ? base + reference : "\(base)/\(reference)"
    }
}
