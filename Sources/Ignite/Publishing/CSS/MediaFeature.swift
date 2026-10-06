//
// MediaFeature.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// An internal type used to represent true medai query features during CSS
/// generation, as not all types that conform to `Query` are valid features.
protocol MediaFeature: CustomStringConvertible {
    var description: String { get }
}

extension MediaFeature where Self == BreakpointQuery {
    /// Creates a breakpoint media feature.
    /// - Parameter breakpoint: The breakpoint to apply.
    /// - Returns: A breakpoint media feature.
    static func breakpoint(_ breakpoint: BreakpointQuery) -> BreakpointQuery {
        breakpoint
    }
}
