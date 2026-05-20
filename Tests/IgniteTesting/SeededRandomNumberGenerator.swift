//
// SeededRandomNumberGenerator.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A deterministic random number generator using SplitMix64.
/// Use in tests to get reproducible "random" values across runs.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound) + 1
        return range.lowerBound + Int(next() % span)
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        let fraction = Double(next()) / Double(UInt64.max)
        return range.lowerBound + fraction * (range.upperBound - range.lowerBound)
    }

    mutating func nextBool() -> Bool {
        next() % 2 == 0
    }

    mutating func nextElement<T>(from array: [T]) -> T {
        array[Int(next() % UInt64(array.count))]
    }
}
