//
//  EmbedURLSafetyTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that the provider initializers of `Embed` keep a caller's ID inside
/// the path of the provider's URL, whatever characters the ID contains.
@Suite("Embed URL Safety Tests")
class EmbedURLSafetyTests: IgniteTestSuite {
    @Test("Ordinary IDs produce the same URLs as before", .publishingContext())
    func ordinaryIDs() async throws {
        #expect(Embed(youTubeID: "dQw4w9WgXcQ", title: "").url
                == "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ")
        #expect(Embed(youTubeID: "a-b_C1", title: "").url
                == "https://www.youtube-nocookie.com/embed/a-b_C1")
        #expect(Embed(vimeoID: 123456, title: "").url
                == "https://player.vimeo.com/video/123456")
        #expect(Embed(spotifyID: "abc123", title: "", type: .track, theme: 1).url
                == "https://open.spotify.com/embed/track/abc123?utm_source=generator&theme=1")
        #expect(Embed(spotifyID: "pl123", title: "", type: .playlist).url
                == "https://open.spotify.com/embed/playlist/pl123?utm_source=generator&theme=0")
    }

    @Test("A YouTube ID cannot add a query or fragment to the embed URL", .publishingContext())
    func youTubeIDStaysInPath() async throws {
        let embed = Embed(youTubeID: "abc?autoplay=1#frag", title: "")

        #expect(embed.url == "https://www.youtube-nocookie.com/embed/abc%3Fautoplay=1%23frag")
    }

    @Test("A Spotify ID cannot add to or replace the embed URL's query", .publishingContext())
    func spotifyIDStaysInPath() async throws {
        let embed = Embed(spotifyID: "abc?theme=9#frag", title: "")

        #expect(embed.url
                == "https://open.spotify.com/embed/track/abc%3Ftheme=9%23frag?utm_source=generator&theme=0")
    }

    @Test("An empty ID does not trap")
    func emptyIDs() async throws {
        #expect(Embed(youTubeID: "", title: "").url == "https://www.youtube-nocookie.com/embed/")
        #expect(Embed(spotifyID: "", title: "").url
                == "https://open.spotify.com/embed/track/?utm_source=generator&theme=0")
    }
}
