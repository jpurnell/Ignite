//
// String-TestingHTML.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension String {
    func htmlTagWithCloseTag(_ tagName: String) -> (attributes: String, contents: String)? {
        guard let regex = try? Regex("(?s)<\(tagName)(.*?)>(.*?)</\(tagName)>") else {
            return nil
        }

        guard let unwrapped = firstMatch(of: regex) else {
            return nil
        }

        return (attributes: String(unwrapped[1].substring ?? ""),
                contents: String(unwrapped[2].substring ?? ""))
    }

    func htmlAttribute(named name: String) -> String? {
        guard let regex = try? Regex("\(name)=\"(.*?)\"") else {
            return nil
        }

        guard let found = firstMatch(of: regex)?[1].substring else { return nil }
        return String(found)
    }
}
