//
//  RequiredMetadataValidatorTests.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation
import Testing

@testable import Ignite

/// Tests for the `RequiredMetadataValidator`.
@Suite("RequiredMetadataValidator Tests")
struct RequiredMetadataValidatorTests {

    static func makeArticle(
        title: String = "Test",
        description: String = "",
        path: String = "blog/test",
        image: String? = nil,
        tags: String? = nil
    ) -> Article {
        var article = Article()
        article.title = title
        article.description = description
        article.path = path
        if let image { article.metadata["image"] = image }
        if let tags { article.metadata["tags"] = tags }
        return article
    }

    @Test("Articles with all required fields pass")
    func allFieldsPresent() {
        let articles = [
            Self.makeArticle(description: "A post about Swift", image: "/img/swift.png")
        ]
        let validator = RequiredMetadataValidator()
        let findings = validator.validate(articles: articles)
        #expect(findings.isEmpty)
    }

    @Test("Missing description produces warning")
    func missingDescription() {
        let articles = [Self.makeArticle(image: "/img/test.png")]
        let validator = RequiredMetadataValidator()
        let findings = validator.validate(articles: articles)

        #expect(findings.count == 1)
        #expect(findings.first?.severity == .warning)
        #expect(findings.first?.message.contains("description") == true)
    }

    @Test("Missing image produces warning")
    func missingImage() {
        let articles = [Self.makeArticle(description: "Has a description")]
        let validator = RequiredMetadataValidator()
        let findings = validator.validate(articles: articles)

        #expect(findings.count == 1)
        #expect(findings.first?.message.contains("image") == true)
    }

    @Test("Multiple missing fields produce multiple findings")
    func multipleMissing() {
        let articles = [Self.makeArticle()]
        let validator = RequiredMetadataValidator()
        let findings = validator.validate(articles: articles)

        #expect(findings.count == 2)
    }

    @Test("Custom required fields are checked")
    func customFields() {
        let articles = [Self.makeArticle()]
        var validator = RequiredMetadataValidator()
        validator.requiredFields = ["tags"]
        let findings = validator.validate(articles: articles)

        #expect(findings.count == 1)
        #expect(findings.first?.message.contains("tags") == true)
    }

    @Test("Empty article list produces no findings")
    func emptyArticles() {
        let validator = RequiredMetadataValidator()
        let findings = validator.validate(articles: [])
        #expect(findings.isEmpty)
    }

    @Test("Validator name is set correctly")
    func validatorName() {
        let validator = RequiredMetadataValidator()
        #expect(validator.name == "RequiredMetadataValidator")
    }

    @Test("Source includes article path")
    func sourceIncludesPath() {
        let articles = [Self.makeArticle(path: "blog/my-post")]
        let validator = RequiredMetadataValidator()
        let findings = validator.validate(articles: articles)

        #expect(findings.allSatisfy { $0.source == "blog/my-post" })
    }
}
