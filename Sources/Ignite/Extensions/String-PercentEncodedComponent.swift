//
// String-PercentEncodedComponent.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension String {
    /// This string percent-encoded so that it is one component of an address – a path
    /// segment, or the value of a query item – and nothing more.
    ///
    /// Only the characters RFC 3986 calls unreserved (letters, digits, `-`, `.`, `_`, `~`)
    /// are left as they are. Everything else, including `/`, `?`, `&`, `=`, `#` and quotes,
    /// is encoded, so an identifier placed into an address cannot add a path, a query
    /// item or a fragment of its own.
    /// - Returns: The encoded string. Identifiers made of unreserved characters are unchanged.
    func percentEncodedAsURLComponent() -> String {
        var unreserved = CharacterSet()
        unreserved.insert(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
    }
}
