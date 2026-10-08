//
//  PublishingErrorPropagationTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests that failures while publishing are thrown to the caller rather than
/// stopping the process.
@Suite("Publishing Error Propagation Tests")
class PublishingErrorPropagationTests: IgniteTestSuite {
    /// Parses a Markdown string as an article by way of a temporary file.
    private func article(fromMarkdown markdown: String) throws -> Article {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "ignite-propagation-\(UUID().uuidString).md")
        try Data(markdown.utf8).write(to: url)
        defer {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                Issue.record("Could not remove temporary article: \(error)")
            }
        }

        let resourceValues = try url.resourceValues(forKeys: Set(Article.resourceKeys))
        return try Article(
            from: url,
            resourceValues: resourceValues,
            deployPath: "posts/example",
            context: publishingContext
        )
    }

    @Test("Copying a resource Ignite does not ship throws missingSiteResource", .publishingContext())
    func missingResourceThrows() async throws {
        let error = #expect(throws: PublishingError.self) {
            try self.publishingContext.copy(resource: "css/no-such-file.css")
        }

        #expect(error?.errorDescription == "Failed to locate critical site resource: css/no-such-file.css.")
    }

    @Test("An article naming a layout the site does not have throws missingNamedLayout", .publishingContext())
    func missingNamedLayoutThrows() async throws {
        let article = try article(fromMarkdown: "---\nlayout: NoSuchLayout\n---\nBody")

        let error = #expect(throws: PublishingError.self) {
            _ = try self.publishingContext.layout(for: article)
        }

        #expect(error?.errorDescription == PublishingError.missingNamedLayout("NoSuchLayout").errorDescription)
    }

    @Test("An article naming a layout the site has still resolves it", .publishingContext())
    func namedLayoutResolves() async throws {
        let article = try article(fromMarkdown: "---\nlayout: TestStory\n---\nBody")
        let layout = try publishingContext.layout(for: article)

        #expect(String(describing: type(of: layout)) == "TestStory")
    }
}
