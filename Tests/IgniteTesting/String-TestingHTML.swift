//
// String-TestingHTML.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

extension String {
    // no, this isn't appropriate for general HTML parsing,
    // but for our purposes, testing nested tags,
    // it should work fine
    func htmlTagWithCloseTag(_ tagName: String) -> (attributes: String, contents: String)? {
        // if the pattern fails to compile, there is something wrong at the call site
        // (maybe tagName is malformed?), so record it as a test failure rather than trapping
        let regex: Regex<AnyRegexOutput>
        do {
            regex = try Regex("(?s)<\(tagName)(.*?)>(.*?)</\(tagName)>")
        } catch {
            Issue.record(error, "Could not build a tag regex for '\(tagName)'")
            return nil
        }

        guard let unwrapped = firstMatch(of: regex) else {
            return nil
        }

        return (attributes: String(unwrapped[1].substring ?? ""),
                contents: String(unwrapped[2].substring ?? ""))
    }

    // no, this isn't appropriate for general HTML parsing,
    // but for our purposes, testing output, it should work fine
    func htmlAttribute(named name: String) -> String? {
        // if the pattern fails to compile, there is something wrong at the call site
        // (maybe name is malformed?), so record it as a test failure rather than trapping
        let regex: Regex<AnyRegexOutput>
        do {
            regex = try Regex("\(name)=\"(.*?)\"")
        } catch {
            Issue.record(error, "Could not build an attribute regex for '\(name)'")
            return nil
        }

        guard let found = firstMatch(of: regex)?[1].substring else { return nil }
        return String(found)
    }
}
