//
// FontFace.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Represents a CSS @font-face rule
struct FontFaceRule: Hashable, Equatable, Sendable {
    let family: String

    /// The address of the font file, as it is written inside `url()`.
    let source: String
    let weight: String
    let style: String
    let display: String

    init(
        family: String,
        source: String,
        weight: String = "normal",
        style: String = "normal",
        display: String = "swap"
    ) {
        self.family = family
        self.source = source
        self.weight = weight
        self.style = style
        self.display = display
    }

    func render() -> String {
        """
        @font-face {
            font-family: \(family.cssStringLiteral());
            src: url(\(source.cssStringLiteral()));
            font-weight: \(weight);
            font-style: \(style);
            font-display: \(display);
        }
        """
    }
}

extension FontFaceRule: CustomStringConvertible {
    var description: String {
        render()
    }
}
