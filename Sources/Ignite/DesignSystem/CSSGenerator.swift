//
//  CSSGenerator.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// Compiles design tokens to CSS custom properties.
public enum CSSGenerator {
    /// Generates a `:root` block with CSS custom properties from the given tokens.
    public static func generate(from tokens: [AnyDesignToken]) -> String {
        var lines = [":root {"]
        for token in tokens {
            lines.append("  \(token.cssProperty): \(token.cssValue);")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    /// Generates a `prefers-color-scheme: dark` media query with token overrides.
    public static func generateDarkMode(from overrides: [AnyDesignToken]) -> String {
        var lines = ["@media (prefers-color-scheme: dark) {", "  :root {"]
        for token in overrides {
            lines.append("    \(token.cssProperty): \(token.cssValue);")
        }
        lines.append("  }")
        lines.append("}")
        return lines.joined(separator: "\n")
    }
}
