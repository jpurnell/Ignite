//
// Array2D.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A generic 2D array implementation.
struct Array2D<T> {
    /// The number of columns in the array.
    let columns: Int

    /// The number of rows in the array.
    let rows: Int

    /// The underlying storage.
    private var array: [T]

    /// The array data as a flattened array.
    var flattened: [T] { array }

    /// Creates a 2D array with the specified dimensions and initial value.
    /// - Parameters:
    ///   - rows: The number of rows.
    ///   - columns: The number of columns.
    ///   - initialValue: The value to fill the array with.
    init(rows: Int, columns: Int, initialValue: T) {
        self.rows = rows
        self.columns = columns
        self.array = .init(repeating: initialValue, count: rows*columns)
    }

    /// Creates a 2D array from a flattened array.
    /// - Parameters:
    ///   - rows: The number of rows.
    ///   - columns: The number of columns.
    ///   - flattened: The data as a flattened array.
    /// - Returns: `nil` if either dimension is negative, or if `flattened`
    /// does not contain exactly `rows * columns` values.
    init?(rows: Int, columns: Int, flattened: [T]) {
        guard rows >= 0, columns >= 0, rows * columns == flattened.count else {
            return nil
        }
        self.rows = rows
        self.columns = columns
        self.array = flattened
    }

    /// Returns the position of a cell in the underlying storage.
    /// - Parameters:
    ///   - row: The row index.
    ///   - column: The column index.
    /// - Returns: The storage index, or `nil` if the cell lies outside the array.
    private func storageIndex(row: Int, column: Int) -> Int? {
        guard row >= 0, row < rows, column >= 0, column < columns else {
            return nil
        }
        return (row * columns) + column
    }

    /// Reads an individual cell in the array.
    /// - Parameters:
    ///   - row: The row index.
    ///   - column: The column index.
    /// - Returns: The value in the cell, or `nil` if the cell lies outside the array.
    subscript(row: Int, column: Int) -> T? {
        guard let index = storageIndex(row: row, column: column) else {
            return nil
        }
        return array[index]
    }

    /// Writes an individual cell in the array.
    /// - Parameters:
    ///   - value: The value to store.
    ///   - row: The row index.
    ///   - column: The column index.
    /// - Returns: `true` if the value was stored, or `false` if the cell lies
    /// outside the array, in which case the array is unchanged.
    @discardableResult
    mutating func set(_ value: T, row: Int, column: Int) -> Bool {
        guard let index = storageIndex(row: row, column: column) else {
            return false
        }
        array[index] = value
        return true
    }
}
