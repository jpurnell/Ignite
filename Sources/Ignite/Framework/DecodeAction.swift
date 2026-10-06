//
// ResourceDecoder.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

/// Finds, loads and decodes files in the Resources folder of your site, usually through
/// `@Environment(\.decode)`.
public struct DecodeAction: Sendable {
    /// The root directory for the user's website package.
    var sourceDirectory: URL

    /// Returns the contents of a file in your Resources folder, if it exists.
    /// - Parameter resource: The file to look for, e.g. "quotes.json"
    /// - Returns: A `Data` instance of the file's contents, if it can be found.
    public func data(forResource resource: String) -> Data? {
        guard let url = url(forResource: resource) else { return nil }

        do {
            return try Data(contentsOf: url)
        } catch {
            let reason = error.localizedDescription
            logger.error("Failed to load \(resource, privacy: .public): \(reason, privacy: .public)")
            return nil
        }
    }

    /// Returns the full path to a file in your Resources folder, if it exists.
    /// - Parameter resource: The file to look for, e.g. "quotes.json"
    /// - Returns: The URL, if the file can be found.
    public func url(forResource resource: String) -> URL? {
        let fullURL = sourceDirectory.appending(path: "Resources/\(resource)")

        if FileManager.default.fileExists(atPath: fullURL.decodedPath) {
            return fullURL
        } else {
            return nil
        }
    }

    /// Locates, loads, and decodes a JSON file in your Resources folder.
    /// - Parameters:
    ///   - resource: The file to look for, e.g. "quotes.json".
    ///   - type: The type to decode to, e.g. `[String].self`.
    ///   - dateDecodingStrategy: How to decode dates. Defaults to `.deferredToDate`.
    ///   - keyDecodingStrategy: How to decode keys. Defaults to `.useDefaultKeys`.
    /// - Returns: The decoded type, if the file exists, can be loaded, and decodes
    /// correctly, otherwise nil.
    public func callAsFunction<T: Decodable>(
        _ resource: String,
        as type: T.Type = T.self,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    ) -> T? {
        guard let url = url(forResource: resource) else {
            report("Failed to locate \(resource) in Resources folder.")
            return nil
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            let reason = error.localizedDescription
            logger.error("Failed to load \(resource, privacy: .public): \(reason, privacy: .public)")
            report("Failed to load \(resource)")
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // The message says what went wrong, so sending back
            // `nil` is enough to mean "not decoded."
            let message = Self.failureMessage(for: error, resource: resource)
            logger.error("\(message, privacy: .public)")
            report(message)
            return nil
        }
    }

    /// Describes why a resource could not be decoded, for the site's author.
    /// - Parameters:
    ///   - error: The error thrown while decoding.
    ///   - resource: The file that was being decoded, e.g. "quotes.json".
    /// - Returns: A one-line explanation naming the resource.
    static func failureMessage(for error: any Error, resource: String) -> String {
        switch error {
        case let DecodingError.keyNotFound(key, context):
            "Failed to decode \(resource) due to missing key '\(key.stringValue)' – \(context.debugDescription)"
        case let DecodingError.typeMismatch(_, context):
            "Failed to decode \(resource) due to type mismatch – \(context.debugDescription)"
        case let DecodingError.valueNotFound(type, context):
            "Failed to decode \(resource) due to missing \(type) value – \(context.debugDescription)"
        case DecodingError.dataCorrupted:
            "Failed to decode \(resource) because it appears to be invalid JSON."
        default:
            "Failed to decode \(resource): \(error.localizedDescription)"
        }
    }

    /// Tells the site's author that a resource could not be used, on the output
    /// of the publish in progress, or standard output when there is none.
    private func report(_ message: String) {
        (PublishingContext.current?.output ?? .standard).line(message)
    }
}
