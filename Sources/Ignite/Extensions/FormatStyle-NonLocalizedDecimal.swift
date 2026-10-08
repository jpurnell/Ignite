//
// FormatStyle-NonLocalizedDecimal.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Double>, FormatInput == Double {
    /// A format style that displays a floating point number with one decimal place,
    /// enforcing the use of a `.` as the decimal separator.
    static var nonLocalizedDecimal: Self {
        nonLocalizedDecimal(places: 1)
    }

    /// A format style that displays a floating point number enforcing the use of a `.` as the decimal separator.
    ///
    /// The result is for CSS and HTML, so it has no grouping separators either: 1234.5 is
    /// written `1234.5`, never `1,234.5`. The locale is fixed, so the locale of whoever runs
    /// the build has no say in it.
    /// - Parameter places: The number of decimal places to display. Defaults to 1.
    static func nonLocalizedDecimal(places: Int = 1) -> Self {
        let precision = max(0, places)
        return FloatingPointFormatStyle()
            .precision(.fractionLength(0...precision))
            .grouping(.never)
            .locale(Locale(identifier: "en_US_POSIX"))
    }
}

extension FormatStyle where Self == FloatingPointFormatStyle<Float>, FormatInput == Float {
    /// A format style that displays a floating point number with one decimal place,
    /// enforcing the use of a `.` as the decimal separator.
    static var nonLocalizedDecimal: Self {
        nonLocalizedDecimal(places: 1)
    }

    /// A format style that displays a floating point number enforcing the use of a `.` as the decimal separator.
    ///
    /// The result is for CSS and HTML, so it has no grouping separators either: 1234.5 is
    /// written `1234.5`, never `1,234.5`. The locale is fixed, so the locale of whoever runs
    /// the build has no say in it.
    /// - Parameter places: The number of decimal places to display. Defaults to 1.
    static func nonLocalizedDecimal(places: Int = 1) -> Self {
        let precision = max(0, places)
        return FloatingPointFormatStyle()
            .precision(.fractionLength(0...precision))
            .grouping(.never)
            .locale(Locale(identifier: "en_US_POSIX"))
    }
}
