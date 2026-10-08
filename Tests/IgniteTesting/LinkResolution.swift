//
// LinkResolution.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Checks that the references in a published site lead to files the site contains.
///
/// It reads every HTML file in a build directory, takes each `href`, `src` and `srcset`
/// from it, and resolves the reference the way the thing that will open the site
/// resolves it. A unit test of one element can only say what that element wrote; this
/// says whether what was written leads anywhere.
enum LinkResolution {
    /// How the published site will be opened.
    enum Host {
        /// Straight from the folder, with `file://`. Nothing fills in `index.html` for a
        /// directory and there is no root to resolve `/` against, so every reference has
        /// to be relative and has to name a file.
        case disk

        /// From a web server, with the build directory served at this address. A path
        /// from the root has to lie within the address's own path, and a directory is
        /// served as its `index.html`.
        case server(URL)
    }

    /// A reference that leads nowhere.
    struct BrokenReference: Equatable, CustomStringConvertible {
        /// The page the reference is written in, relative to the build directory.
        var page: String

        /// The reference as written, with its character references decoded.
        var reference: String

        /// Why it does not resolve.
        var problem: String

        var description: String { "\(page): \(reference) – \(problem)" }
    }

    /// Finds the references in a published site that do not lead to a file in it.
    /// - Parameters:
    ///   - buildDirectory: The directory the site was published to.
    ///   - host: How the site will be opened.
    /// - Returns: Every broken reference, in the order of the pages and of the references
    ///   on each. References to other hosts and to schemes other than `http` and `https`
    ///   are not examined.
    static func brokenReferences(in buildDirectory: URL, openedFrom host: Host) throws -> [BrokenReference] {
        let root = buildDirectory.resolvingSymlinksInPath()
        var broken: [BrokenReference] = []

        for page in try pages(in: root) {
            let html = try String(contentsOf: root.appending(path: page), encoding: .utf8)

            for reference in references(in: html) {
                if let problem = problem(with: reference, on: page, in: root, openedFrom: host) {
                    broken.append(BrokenReference(page: page, reference: reference, problem: problem))
                }
            }
        }

        return broken
    }

    /// Counts the references examined, so a test can tell that the check had work to do.
    static func referenceCount(in buildDirectory: URL) throws -> Int {
        let root = buildDirectory.resolvingSymlinksInPath()
        return try pages(in: root).reduce(0) { count, page in
            let html = try String(contentsOf: root.appending(path: page), encoding: .utf8)
            return count + references(in: html).count
        }
    }

    /// The HTML files beneath a directory, by path relative to it, in a fixed order.
    static func pages(in root: URL) throws -> [String] {
        try FileManager.default.subpathsOfDirectory(atPath: root.path)
            .filter { $0.hasSuffix(".html") }
            .sorted()
    }

    /// Every address written in an `href`, `src` or `srcset` attribute of some markup.
    static func references(in html: String) -> [String] {
        html.matches(of: #/\s(href|src|srcset)="([^"]*)"/#).flatMap { match -> [String] in
            let value = String(match.output.2).decodingHTMLCharacterReferences()

            guard match.output.1 == "srcset" else { return [value] }

            // A source set is a list of addresses, each followed by a density or a width.
            return value.split(separator: ",").compactMap { candidate in
                candidate.split(separator: " ").first.map(String.init)
            }
        }
    }

    /// Resolves one reference and says what is wrong with it, if anything.
    private static func problem(
        with reference: String,
        on page: String,
        in root: URL,
        openedFrom host: Host
    ) -> String? {
        // A reference to a place on the same page leads there by definition.
        guard reference.hasPrefix("#") == false else { return nil }
        guard reference.isEmpty == false else { return "is empty" }

        var address = reference

        if let scheme = URL(string: reference)?.scheme?.lowercased() {
            guard case .server(let siteURL) = host, scheme == "http" || scheme == "https" else {
                // `mailto:`, `tel:` and the like are not files, and from disk an
                // address on a server is someone else's whatever it says.
                return nil
            }

            // An absolute address is examined when it is the site's own.
            let site = siteURL.absoluteString.trimmingSuffix("/")
            guard reference == site || reference.hasPrefix("\(site)/") else { return nil }
            address = sitePrefix(of: siteURL) + reference.dropFirst(site.count)
            if address.isEmpty { address = "/" }
        } else if reference.hasPrefix("//") {
            return nil
        }

        let path = String(address.prefix { $0 != "?" && $0 != "#" })
        let decoded = path.removingPercentEncoding ?? path

        switch host {
        case .disk:
            guard decoded.hasPrefix("/") == false else {
                return "starts at the root of the disk"
            }
            let target = directory(of: page, in: root).appending(path: decoded).standardizedFileURL
            return isFile(target) ? nil : "is not a file; file:// opens nothing for it"

        case .server(let siteURL):
            let prefix = sitePrefix(of: siteURL)
            let target: URL

            if decoded.hasPrefix("/") {
                guard decoded == prefix || decoded.hasPrefix("\(prefix)/") else {
                    return "is outside the site, which is served under '\(prefix)'"
                }
                target = root.appending(path: String(decoded.dropFirst(prefix.count))).standardizedFileURL
            } else {
                target = directory(of: page, in: root).appending(path: decoded).standardizedFileURL
            }

            if isFile(target) || isFile(target.appending(path: "index.html")) { return nil }
            return "is not a file or a directory with an index.html"
        }
    }

    /// The path a site's address puts it under, with no trailing slash.
    private static func sitePrefix(of siteURL: URL) -> String {
        siteURL.path.trimmingSuffix("/")
    }

    /// The directory a page is in.
    private static func directory(of page: String, in root: URL) -> URL {
        root.appending(path: page).deletingLastPathComponent()
    }

    private static func isFile(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            && isDirectory.boolValue == false
    }
}

private extension String {
    /// The string without the suffix, repeated or not, at its end.
    func trimmingSuffix(_ suffix: String) -> String {
        var result = self
        while result.hasSuffix(suffix) {
            result.removeLast(suffix.count)
        }
        return result
    }
}
