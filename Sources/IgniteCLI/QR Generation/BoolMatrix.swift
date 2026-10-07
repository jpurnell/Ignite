//
// BoolMatrix.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// A class that represents a square boolean matrix for QR code data.
///
/// `BoolMatrix` provides a convenient way to access and manipulate the binary data
/// that makes up a QR code.
struct BoolMatrix {
    /// The underlying 2D array storage.
    private var content: Array2D<Bool>

    /// Creates an empty boolean matrix.
    init() {
        self.content = Array2D(rows: 0, columns: 0, initialValue: false)
    }

    /// Creates a boolean matrix with the specified dimension.
    /// - Parameter dimension: The width and height of the square matrix.
    init(dimension: Int) {
        self.content = Array2D(rows: dimension, columns: dimension, initialValue: false)
    }

    /// Creates a boolean matrix from a flattened array.
    /// - Parameters:
    ///   - dimension: The width and height of the square matrix.
    ///   - flattened: The data as a flattened array.
    /// - Returns: `nil` if `flattened` does not contain exactly
    /// `dimension * dimension` values.
    init?(dimension: Int, flattened: [Bool]) {
        guard let content = Array2D(rows: dimension, columns: dimension, flattened: flattened) else {
            return nil
        }
        self.content = content
    }

    /// The width and height of the matrix.
    var dimension: Int { content.rows }

    /// Access individual cells in the matrix.
    ///
    /// Cells outside the matrix read as `false` – an unset module, like the quiet
    /// zone around a QR code – and writes to them are ignored.
    /// - Parameters:
    ///   - row: The row index.
    ///   - column: The column index.
    subscript(row: Int, column: Int) -> Bool {
        get { content[row, column] ?? false }
        set { content.set(newValue, row: row, column: column) }
    }
}
