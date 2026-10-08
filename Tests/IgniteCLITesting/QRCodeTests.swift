//
// QRCodeTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation
import Testing

@testable import IgniteCLI

/// Tests for the grid types behind the QR code that `ignite run` prints.
@Suite("QR Matrix Tests")
struct QRMatrixTests {
    // MARK: - Array2D

    @Test("A grid is filled with its initial value")
    func arrayInitialValue() {
        let grid = Array2D(rows: 2, columns: 3, initialValue: 7)
        #expect(grid.rows == 2)
        #expect(grid.columns == 3)
        for row in 0..<2 {
            for column in 0..<3 {
                #expect(grid[row, column] == 7)
            }
        }
    }

    @Test("A grid made from a flat list is read row by row")
    func arrayFromFlattened() throws {
        let grid = try #require(Array2D(rows: 2, columns: 3, flattened: [1, 2, 3, 4, 5, 6]))
        #expect(grid[0, 0] == 1)
        #expect(grid[0, 2] == 3)
        #expect(grid[1, 0] == 4)
        #expect(grid[1, 2] == 6)
    }

    @Test("A flat list of the wrong length does not make a grid", arguments: [
        (2, 3, 5), (2, 3, 7), (0, 3, 1), (-1, 3, 0), (2, -3, 0), (-2, -3, 6)
    ])
    func arrayFromMismatchedList(rows: Int, columns: Int, count: Int) {
        #expect(Array2D(rows: rows, columns: columns, flattened: Array(repeating: 0, count: count)) == nil)
    }

    @Test("An empty grid can be made, and has nothing in it")
    func emptyArray() throws {
        let grid = try #require(Array2D(rows: 0, columns: 0, flattened: [Int]()))
        #expect(grid[0, 0] == nil)
    }

    @Test("Reading outside a grid gives nothing rather than trapping", arguments: [
        (-1, 0), (0, -1), (2, 0), (0, 3), (2, 3), (Int.max, Int.max), (Int.min, 0)
    ])
    func arrayOutOfRange(row: Int, column: Int) {
        let grid = Array2D(rows: 2, columns: 3, initialValue: 1)
        #expect(grid[row, column] == nil)
    }

    @Test("Setting a value changes that cell and no other")
    func arraySet() {
        var grid = Array2D(rows: 2, columns: 3, initialValue: 0)
        let didSet = grid.set(9, row: 1, column: 2)
        #expect(didSet)
        for row in 0..<2 {
            for column in 0..<3 {
                #expect(grid[row, column] == (row == 1 && column == 2 ? 9 : 0))
            }
        }
    }

    @Test("Setting outside a grid is refused and changes nothing", arguments: [(-1, 0), (0, -1), (2, 0), (0, 3)])
    func arraySetOutOfRange(row: Int, column: Int) {
        var grid = Array2D(rows: 2, columns: 3, initialValue: 0)
        let didSet = grid.set(9, row: row, column: column)
        #expect(didSet == false)
        for row in 0..<2 {
            for column in 0..<3 {
                #expect(grid[row, column] == 0)
            }
        }
    }

    // MARK: - BoolMatrix

    @Test("A new matrix is empty, and a sized one is all false")
    func matrixInitialState() {
        #expect(BoolMatrix().dimension == 0)
        #expect(BoolMatrix()[0, 0] == false)

        let matrix = BoolMatrix(dimension: 3)
        #expect(matrix.dimension == 3)
        for row in 0..<3 {
            for column in 0..<3 {
                #expect(matrix[row, column] == false)
            }
        }
    }

    @Test("A matrix made from a flat list is read row by row")
    func matrixFromFlattened() throws {
        let matrix = try #require(BoolMatrix(dimension: 2, flattened: [true, false, false, true]))
        #expect(matrix[0, 0] == true)
        #expect(matrix[0, 1] == false)
        #expect(matrix[1, 0] == false)
        #expect(matrix[1, 1] == true)
    }

    @Test("A flat list that is not a square of the dimension does not make a matrix", arguments: [
        (2, 3), (2, 5), (3, 4), (-1, 1)
    ])
    func matrixFromMismatchedList(dimension: Int, count: Int) {
        #expect(BoolMatrix(dimension: dimension, flattened: Array(repeating: true, count: count)) == nil)
    }

    @Test("Reading outside a matrix gives false, and writing there changes nothing")
    func matrixOutOfRange() {
        var matrix = BoolMatrix(dimension: 2)
        matrix[5, 5] = true
        matrix[-1, 0] = true
        #expect(matrix[5, 5] == false)
        #expect(matrix[-1, 0] == false)
        for row in 0..<2 {
            for column in 0..<2 {
                #expect(matrix[row, column] == false)
            }
        }

        matrix[1, 0] = true
        #expect(matrix[1, 0] == true)
        #expect(matrix[0, 1] == false)
    }

    // MARK: - ErrorCorrection

    @Test("Each error correction level has the letter the QR standard gives it")
    func errorCorrectionLevels() {
        #expect(ErrorCorrection.allCases.map(\.level) == ["L", "M", "Q", "H"])
        #expect(ErrorCorrection.default == .quantize)
    }
}

#if canImport(CoreImage)
/// Tests for the QR code itself, read back from the text `ignite run` prints.
@Suite("QR Code Tests")
struct QRCodeTests {
    /// Reads the half-block text back into a grid of modules, dark being `true`.
    private func modules(of text: String) -> [[Bool]] {
        var rows: [[Bool]] = []

        for line in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).dropLast() {
            var top: [Bool] = []
            var bottom: [Bool] = []

            for character in line {
                top.append(character == "▀" || character == "█")
                bottom.append(character == "▄" || character == "█")
            }

            rows.append(top)
            rows.append(bottom)
        }

        return rows
    }

    /// The side of the code in modules: the printed width.
    private func dimension(of text: String) -> Int {
        text.split(whereSeparator: \.isNewline).first?.count ?? 0
    }

    /// Whether the 7 by 7 finder pattern – a dark ring, a light ring, a dark centre –
    /// has its top-left corner at a position.
    private func hasFinderPattern(in modules: [[Bool]], row: Int, column: Int) -> Bool {
        for offsetRow in 0..<7 {
            for offsetColumn in 0..<7 {
                let onOuterRing = offsetRow == 0 || offsetRow == 6 || offsetColumn == 0 || offsetColumn == 6
                let inCentre = (2...4).contains(offsetRow) && (2...4).contains(offsetColumn)
                guard modules[row + offsetRow][column + offsetColumn] == (onOuterRing || inCentre) else {
                    return false
                }
            }
        }
        return true
    }

    @Test("The printed code is a square of half-block characters, one line for every two rows")
    func printedShape() throws {
        let text = try QRCode(utf8String: "https://192.168.1.20:8000").smallAsciiRepresentation()
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        let side = dimension(of: text)

        // Version 2 at this length and level: 25 modules, with one light module around them.
        #expect(side == 27)
        #expect(lines.last == "")
        #expect(lines.dropLast().count == (side + 1) / 2)
        for line in lines.dropLast() {
            #expect(line.count == side)
            #expect(line.allSatisfy { " ▀▄█".contains($0) })
        }
    }

    @Test("The code has a finder pattern in three corners and not in the fourth")
    func finderPatterns() throws {
        let text = try QRCode(utf8String: "https://192.168.1.20:8000").smallAsciiRepresentation()
        let grid = modules(of: text)
        let side = dimension(of: text)

        // One light module of margin on every side.
        #expect(grid[0].prefix(side).allSatisfy { $0 == false })
        #expect((0..<side).allSatisfy { grid[$0][0] == false })

        #expect(hasFinderPattern(in: grid, row: 1, column: 1))
        #expect(hasFinderPattern(in: grid, row: 1, column: side - 8))
        #expect(hasFinderPattern(in: grid, row: side - 8, column: 1))
        #expect(hasFinderPattern(in: grid, row: side - 8, column: side - 8) == false)
    }

    @Test("The same address always gives the same code, and another address a different one")
    func deterministic() throws {
        let first = try QRCode(utf8String: "https://192.168.1.20:8000").smallAsciiRepresentation()
        let again = try QRCode(utf8String: "https://192.168.1.20:8000").smallAsciiRepresentation()
        let other = try QRCode(utf8String: "https://192.168.1.21:8000").smallAsciiRepresentation()

        #expect(first == again)
        #expect(first != other)
        #expect(dimension(of: first) == dimension(of: other))
    }

    @Test("A longer address needs a larger code, and more error correction a larger one still")
    func sizeGrowsWithContent() throws {
        let short = try QRCode(utf8String: "https://10.0.0.2:8000").smallAsciiRepresentation()
        let long = try QRCode(
            utf8String: "https://192.168.100.200:8000/a/rather/long/subsite/path/for/a/site").smallAsciiRepresentation()
        let low = try QRCode(utf8String: "https://192.168.1.20:8000", errorCorrection: .low).smallAsciiRepresentation()
        let high = try QRCode(utf8String: "https://192.168.1.20:8000", errorCorrection: .high).smallAsciiRepresentation()

        #expect(dimension(of: short) < dimension(of: long))
        #expect(dimension(of: low) < dimension(of: high))
        // Every size of QR code is four modules wider than the last, starting from 21.
        for text in [short, long, low, high] {
            #expect((dimension(of: text) - 2 - 21) % 4 == 0)
        }
    }
}
#endif
