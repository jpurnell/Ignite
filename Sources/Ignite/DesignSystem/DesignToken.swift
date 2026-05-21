//
//  DesignToken.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// A value that can be expressed as a CSS value.
public protocol TokenValue: Sendable {
    var cssValue: String { get }
}

/// Categories of design tokens.
public enum TokenCategory: String, Sendable {
    case color
    case spacing = "space"
    case typography = "type"
    case shadow
    case radius
    case breakpoint = "bp"
}

/// A typed design token that compiles to a CSS custom property.
public struct DesignToken<Value: TokenValue>: Sendable {
    public let name: String
    public let category: TokenCategory
    public let value: Value

    public var cssProperty: String {
        "--ig-\(category.rawValue)-\(name)"
    }

    public var cssVar: String {
        "var(\(cssProperty))"
    }

    public init(name: String, category: TokenCategory, value: Value) {
        self.name = name
        self.category = category
        self.value = value
    }

    /// Type-erases this token for use in heterogeneous collections.
    public var erased: AnyDesignToken {
        AnyDesignToken(cssProperty: cssProperty, cssValue: value.cssValue)
    }
}

/// A type-erased design token for heterogeneous collections.
public struct AnyDesignToken: Sendable {
    public let cssProperty: String
    public let cssValue: String
}
