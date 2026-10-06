//
// Embed.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// Embeds a custom URL, such as YouTube or Vimeo.
public struct Embed: HTML, LazyLoadable {
    /// Determines what kind of Spotify embed we have.
    public enum SpotifyContentType: String {
        /// Creates interactive item for a single Spotify track
        case track
        /// Creates interactive  item for a Spotify playlist
        case playlist
        /// Create interactive item for a Spotify artist
        case artist
        /// Creates interactive item for a Spotify album
        case album
        /// Creates interactive item for a Spotify podcast
        case show
        /// Creates interactive item for a Spotify episode
        case episode
    }

    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    /// The URL we're embedding inside our page.
    let url: String

    /// A title that describes this content.
    let title: String

    /// Creates a new `Embed` instance from the titl and URL provided.
    /// - Parameters:
    ///   - title: A title suitable for screenreaders.
    ///   - url: The URL to embed on your page.
    public init(title: String, url: URL) {
        self.url = url.absoluteString
        self.title = title
    }

    /// Creates a new `Embed` instance from the title and URL provided.
    /// - Parameters:
    ///   - title: A title suitable for screen readers.
    ///   - url: The URL to embed on your page.
    public init(title: String, url: String) {
        self.url = url
        self.title = title
    }

    /// Creates a new `Embed` instance from the title and Vimeo ID provided.
    /// - Parameters:
    ///   - vimeoID: The Vimeo ID to use.
    ///   - title: A title suitable for screen readers.
    public init(vimeoID: Int, title: String) {
        self.url = Self.providerURL(host: "player.vimeo.com", path: ["video", String(vimeoID)])
        self.title = title
    }

    /// Creates a new `Embed` instance from the title and YouTube ID provided.
    /// - Parameters:
    ///   - youTubeID: The YouTube ID to use.
    ///   - title: A title suitable for screen readers.
    public init(youTubeID: String, title: String) {
        self.url = Self.providerURL(host: "www.youtube-nocookie.com", path: ["embed", youTubeID])
        self.title = title
    }

    /// Creates a new `Embed` instance from the title and Spotify ID provided.
    /// - Parameters:
    ///   - spotifyID: The Spotify ID to use.
    ///   - title: A title suitable for screen readers.
    ///   - type: The SpotifyContentType to use.
    ///   - theme: Either 0 or 1, each representing one of the two theme
    ///   options offered by Spotify, which can be found in the code they provide.
    public init(spotifyID: String, title: String, type: SpotifyContentType = .track, theme: Int = 0) {
        self.url = Self.providerURL(
            host: "open.spotify.com",
            path: ["embed", type.rawValue, spotifyID],
            queryItems: [
                URLQueryItem(name: "utm_source", value: "generator"),
                URLQueryItem(name: "theme", value: String(theme))
            ])
        self.title = title
    }

    /// Builds the HTTPS address of a provider's embed page.
    ///
    /// The host is fixed by the caller inside Ignite and the caller's ID only ever
    /// lands in the path, where anything that would otherwise start a query or a
    /// fragment is percent-encoded. An ID therefore cannot change which site is
    /// embedded, nor the query Ignite adds.
    /// - Parameters:
    ///   - host: The provider's host name.
    ///   - path: The path, one component per element.
    ///   - queryItems: Query items to add. Defaults to none.
    /// - Returns: The address as a string, ready for an `iframe`'s `src`.
    private static func providerURL(host: String, path: [String], queryItems: [URLQueryItem] = []) -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/" + path.joined(separator: "/")

        if queryItems.isEmpty == false {
            components.queryItems = queryItems
        }

        // A scheme, a host and an absolute path always form a URL; should Foundation
        // ever disagree, the provider's own root is the closest honest answer.
        return components.string ?? "https://\(host)"
    }

    /// Renders this element using publishing context passed in.
    /// - Returns: The HTML for this element.
    public func markup() -> Markup {
        // Enough permissions for users to accomplish common
        // tasks safely.
        let allowPermissions = """
            accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share
            """

        if attributes.classes.contains("ratio") == false {
            publishingContext.addWarning("""
            Embedding \(url) without an aspect ratio will cause it to appear very small. \
            It is recommended to use aspectRatio() so it can scale automatically.
            """)
        }

        return Section {
             #"<iframe src="\#(url)" title="\#(title)" allow="\#(allowPermissions)"></iframe>"#
        }
        .attributes(attributes)
        .markup()
    }
}
