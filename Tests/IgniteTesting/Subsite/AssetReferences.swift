//
//  AssetReferences.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// A site at the root of its host or in a subdirectory of it, with or without a trailing
/// slash on its address.
private struct AddressedSite: Site {
    var name = "Addressed"
    var url: URL
    var homePage = TestPage()
    var layout = EmptyLayout()
}

/// Where a test site lives, and the prefix every root-relative asset reference on it needs.
struct SiteAddress: Sendable, CustomTestStringConvertible {
    let address: String
    let prefix: String

    var testDescription: String { address }

    static let all: [SiteAddress] = [
        SiteAddress(address: "https://www.example.com", prefix: ""),
        SiteAddress(address: "https://www.example.com/", prefix: ""),
        SiteAddress(address: "https://www.example.com/subsite", prefix: "/subsite"),
        SiteAddress(address: "https://www.example.com/subsite/", prefix: "/subsite"),
        SiteAddress(address: "https://www.example.com/a/b", prefix: "/a/b")
    ]
}

/// Every reference to a file the site itself serves – scripts, stylesheets, images, fonts,
/// icons, audio and video – is resolved the same way: a root-relative path is prefixed with
/// the path of the site, so a site deployed in a subdirectory finds its own files, and
/// anything else is left alone.
@Suite("Asset reference Tests")
class AssetReferenceTests: IgniteTestSuite {
    private func render<T>(at address: SiteAddress, _ operation: (PublishingContext) throws -> T) throws -> T {
        let site = AddressedSite(url: try #require(URL(string: address.address)))
        return try withPublishingContext(for: site, operation: operation)
    }

    // MARK: - The shared rule

    @Test("A root-relative path is prefixed with the site's path, once", arguments: SiteAddress.all)
    func rootRelativePath(address: SiteAddress) throws {
        let path = try render(at: address) { $0.assetPath("/css/styles.css") }

        #expect(path == "\(address.prefix)/css/styles.css")
    }

    @Test("Paths that do not start at the site's root are left alone", arguments: SiteAddress.all, [
        "css/styles.css", "../styles.css", "https://cdn.example.com/styles.css", "//cdn.example.com/styles.css",
        "data:text/css,body{}", "#top", ""
    ])
    func otherPathsAreUntouched(address: SiteAddress, path: String) throws {
        #expect(try render(at: address) { $0.assetPath(path) } == path)
    }

    // MARK: - Scripts

    @Test("A script file is prefixed like any other asset", arguments: SiteAddress.all)
    func scriptFile(address: SiteAddress) throws {
        let output = try render(at: address) { _ in Script(file: "/js/code.js").markupString() }

        #expect(output == #"<script src="\#(address.prefix)/js/code.js"></script>"#)
    }

    @Test("A script that is not root-relative is left alone", arguments: SiteAddress.all, [
        "code.js", "https://cdn.example.com/code.js", "//cdn.example.com/code.js"
    ])
    func scriptElsewhere(address: SiteAddress, file: String) throws {
        let output = try render(at: address) { _ in Script(file: file).markupString() }

        #expect(output == #"<script src="\#(file)"></script>"#)
    }

    @Test("A script given as a remote URL is left alone", arguments: SiteAddress.all)
    func scriptRemoteURL(address: SiteAddress) throws {
        let remote = try #require(URL(string: "https://cdn.example.com/lib.js?v=2"))
        let output = try render(at: address) { _ in Script(file: remote).markupString() }

        #expect(output == #"<script src="https://cdn.example.com/lib.js?v=2"></script>"#)
    }

    @Test("The scripts Ignite adds to the body are prefixed", arguments: SiteAddress.all)
    func bodyScripts(address: SiteAddress) throws {
        let output = try render(at: address) { _ in Body { Text("TEXT") }.markupString() }

        #expect(output == """
        <body class="container"><p>TEXT</p>\
        <script src="\(address.prefix)/js/bootstrap.bundle.min.js"></script>\
        <script src="\(address.prefix)/js/ignite-core.js"></script></body>
        """)
    }

    // MARK: - Stylesheets and icons

    @Test("Stylesheets are prefixed", arguments: SiteAddress.all)
    func stylesheets(address: SiteAddress) throws {
        let output = try render(at: address) { _ in
            MetaLink.standardCSS.markupString() + MetaLink.igniteCoreCSS.markupString()
        }

        #expect(output == """
        <link href="\(address.prefix)/css/bootstrap.min.css" rel="stylesheet" />\
        <link href="\(address.prefix)/css/ignite-core.min.css" rel="stylesheet" />
        """)
    }

    @Test("A favicon is prefixed", arguments: SiteAddress.all)
    func favicon(address: SiteAddress) throws {
        let icon = try #require(URL(string: "/favicon.ico"))
        let output = try render(at: address) { _ in MetaLink(href: icon, rel: .icon).markupString() }

        #expect(output == #"<link href="\#(address.prefix)/favicon.ico" rel="icon" />"#)
    }

    // MARK: - Images

    @Test("An image is prefixed", arguments: SiteAddress.all)
    func image(address: SiteAddress) throws {
        let output = try render(at: address) { _ in
            Image("/images/example.jpg", description: "Example").markupString()
        }

        #expect(output == #"<img src="\#(address.prefix)/images/example.jpg" alt="Example" />"#)
    }

    @Test("A background image is prefixed", arguments: SiteAddress.all)
    func backgroundImage(address: SiteAddress) throws {
        let output = try render(at: address) { _ in
            Text("Hello").background(image: "/images/bg.png", contentMode: .fill).markupString()
        }

        #expect(output == """
        <p style="background-image: url('\(address.prefix)/images/bg.png'); background-size: cover; \
        background-repeat: no-repeat; background-position: center center">Hello</p>
        """)
    }

    @Test("A background image that is not root-relative is left alone", arguments: SiteAddress.all, [
        "assets/image.png", "https://cdn.example.com/bg.png"
    ])
    func backgroundImageElsewhere(address: SiteAddress, image: String) throws {
        let output = try render(at: address) { _ in
            Text("Hello").background(image: image, contentMode: .fill).markupString()
        }

        #expect(output == """
        <p style="background-image: url('\(image)'); background-size: cover; \
        background-repeat: no-repeat; background-position: center center">Hello</p>
        """)
    }

    // MARK: - Audio and video

    @Test("Audio sources are prefixed", arguments: SiteAddress.all)
    func audio(address: SiteAddress) throws {
        let output = try render(at: address) { _ in
            Audio("/audio/bark.mp3", "https://cdn.example.com/bark.wav").markupString()
        }

        #expect(output == """
        <audio controls>\
        <source src="\(address.prefix)/audio/bark.mp3" type="audio/mpeg">\
        <source src="https://cdn.example.com/bark.wav" type="audio/wav">\
        Your browser does not support the audio element.</audio>
        """)
    }

    @Test("Video sources are prefixed", arguments: SiteAddress.all)
    func video(address: SiteAddress) throws {
        let output = try render(at: address) { _ in
            Video("/videos/clip.mp4", "https://cdn.example.com/clip.webm").markupString()
        }

        #expect(output == """
        <video controls>\
        <source src="\(address.prefix)/videos/clip.mp4" type="video/mp4" />\
        <source src="https://cdn.example.com/clip.webm" type="video/webm" />\
        Your browser does not support the video tag.</video>
        """)
    }

    // MARK: - Fonts

    @Test("A font file served by the site is prefixed in its @font-face rule", arguments: SiteAddress.all)
    func fontFace(address: SiteAddress) throws {
        let local = try #require(URL(string: "/fonts/custom.woff2"))
        let remote = try #require(URL(string: "https://cdn.example.com/custom-bold.woff2"))
        let font = Font(name: "Custom", sources: FontSource(url: local), FontSource(weight: .bold, url: remote))

        let rules = try render(at: address) { $0.fontRules(for: [font]) }

        #expect(rules == [
            """
            @font-face {
                font-family: 'Custom';
                src: url('\(address.prefix)/fonts/custom.woff2');
                font-weight: 400;
                font-style: normal;
                font-display: swap;
            }
            """,
            """
            @font-face {
                font-family: 'Custom';
                src: url('https://cdn.example.com/custom-bold.woff2');
                font-weight: 700;
                font-style: normal;
                font-display: swap;
            }
            """
        ])
    }

    // MARK: - Relative-path sites

    @Test("A site using relative paths writes scripts the way it writes stylesheets")
    func relativePathSite() throws {
        let output = try withPublishingContext(for: TestRelativePathsSite()) { _ in
            Script(file: "/js/code.js").markupString()
                + MetaLink(href: "/css/styles.css", rel: .stylesheet).markupString()
        }

        #expect(output == #"<script src="js/code.js"></script><link href="css/styles.css" rel="stylesheet" />"#)
    }

    @Test("A font in a stylesheet keeps its root-relative address on a relative-path site")
    func relativePathSiteFont() throws {
        let local = try #require(URL(string: "/fonts/custom.woff2"))
        let font = Font(name: "Custom", sources: FontSource(url: local))

        let rules = try withPublishingContext(for: TestRelativePathsSite()) { $0.fontRules(for: [font]) }

        #expect(rules == [
            """
            @font-face {
                font-family: 'Custom';
                src: url('/fonts/custom.woff2');
                font-weight: 400;
                font-style: normal;
                font-display: swap;
            }
            """
        ])
    }
}
