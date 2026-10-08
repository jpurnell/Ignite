//
// BinaryInteger-MarkupDigits.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

extension BinaryInteger {
    /// This number in ASCII decimal digits, with no grouping separators, for writing into
    /// HTML attributes, CSS and JavaScript.
    ///
    /// Those are read by a parser rather than a person, so they must not follow the locale
    /// of whoever runs the build: `formatted()` writes 5000 as `5,000` under `en_US`,
    /// `5.000` under `de_DE` and `٥٬٠٠٠` under `ar_EG`, none of which a browser reads as
    /// five thousand. This never consults a locale.
    var markupDigits: String {
        String(self, radix: 10)
    }
}
