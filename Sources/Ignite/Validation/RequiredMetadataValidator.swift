//
//  RequiredMetadataValidator.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// Enforces that articles have required front matter fields.
public struct RequiredMetadataValidator: SiteValidator {
    public let name = "RequiredMetadataValidator"

    /// Front matter fields that every article must have.
    public var requiredFields: Set<String> = ["description", "image"]

    public init() {}

    public func validate(articles: [Article]) -> [ValidationRule] {
        articles.flatMap { article in
            requiredFields.sorted().compactMap { field in
                let hasField: Bool = switch field {
                case "description":
                    !article.description.isEmpty
                case "image":
                    article.metadata["image"] != nil
                default:
                    article.metadata[field] != nil
                }

                guard !hasField else { return nil }

                return ValidationRule(
                    severity: .warning,
                    message: "Article \"\(article.title)\" is missing required field: \(field)",
                    source: article.path,
                    target: nil,
                    validatorName: name
                )
            }
        }
    }
}
