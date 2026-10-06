//
// PageNotFoundError.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// An HTTP error that represents a page not found.
public struct PageNotFoundError: HTTPError {
    /// The HTTP status code, which is 404.
    public let statusCode: Int
    /// The title of the error, which is "Page Not Found".
    public let title: String
    /// A sentence telling the visitor that the page could not be found.
    public let description: String

    /// Creates a page-not-found error with the status code 404.
    public init() {
        self.statusCode = 404
        self.title = "Page Not Found"
        self.description = "The page you are looking for could not be found."
    }
}

public extension HTTPError where Self == PageNotFoundError {
    /// An HTTP error that represents a page not found.
    static var pageNotFound: HTTPError {
        PageNotFoundError()
    }
}
