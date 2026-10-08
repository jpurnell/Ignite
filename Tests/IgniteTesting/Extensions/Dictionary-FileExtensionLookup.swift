//
//  Dictionary-FileExtensionLookup.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Testing

@testable import Ignite

/// Tests for finding a media type from a file name, which must give one answer per name.
@Suite("Dictionary-FileExtensionLookup Tests")
struct DictionaryFileExtensionLookupTests {
    private static let table = [".it": "it", ".item": "item", ".mp3": "mp3", ".aif": "aif", ".aifc": "aifc", ".wavX": "wavx"]

    @Test("A file is typed by its extension", arguments: [
        ("song.mp3", "mp3"), ("/audio/song.aif", "aif"), ("/audio/song.aifc", "aifc"), ("a.b.c.item", "item"),
        ("SONG.MP3", "mp3"), ("song.wavx", "wavx"), ("song.wavX", "wavx"),
        ("https://example.com/song.mp3?v=2", "mp3"), ("song.mp3#t=10", "mp3")
    ])
    func extensionDecides(filename: String, expected: String) {
        #expect(Self.table.value(forFileNamed: filename) == expected)
    }

    @Test("An extension elsewhere in the name does not decide the type", arguments: [
        ("podcast.item.mp3", "mp3"), ("my.italian.aifc", "aifc"), ("the.aif.item", "item")
    ])
    func lastExtensionWins(filename: String, expected: String) {
        #expect(Self.table.value(forFileNamed: filename) == expected)
    }

    @Test("With no known extension at the end, the longest one found in the name is used", arguments: [
        ("song.aifc.bak", "aifc"), ("song.item.bak", "item"), ("song.mp3.bak", "mp3")
    ])
    func longestContainedExtension(filename: String, expected: String) {
        #expect(Self.table.value(forFileNamed: filename) == expected)
    }

    @Test("A name with no known extension has no type", arguments: ["song", "song.xyz", "", "mp3"])
    func unknown(filename: String) {
        #expect(Self.table.value(forFileNamed: filename) == nil)
    }
}
