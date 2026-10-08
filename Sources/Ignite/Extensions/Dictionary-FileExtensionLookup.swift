//
// Dictionary-FileExtensionLookup.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

extension Dictionary where Key == String {
    /// Looks up a file by its extension in a table keyed by extension, such as `".mp4"`.
    ///
    /// The file's own extension decides: the text after the last `.` of its name, ignoring
    /// a query or a fragment after it and the case of its letters. Only when that is not
    /// in the table is the rest of the name searched, and then the longest extension found
    /// in it is used, the alphabetically first of several of equal length.
    ///
    /// Either way a name has one answer. The lookup this replaces returned whichever
    /// extension it met first while walking the dictionary, whose order changes with every
    /// run: `podcast.item.mp3` was MP3 on one build and `.it` on the next.
    /// - Parameter filename: A file name or path, possibly followed by a query or fragment.
    /// - Returns: The value for the file's extension, or `nil` if the table has none.
    func value(forFileNamed filename: String) -> Value? {
        let pathEnd = filename.firstIndex { $0 == "?" || $0 == "#" } ?? filename.endIndex
        let path = filename[..<pathEnd].lowercased()

        // One entry per extension, lowercased, in an order that does not depend on hashing.
        let entries = self
            .map { (extension: $0.key.lowercased(), value: $0.value) }
            .sorted { first, second in
                first.extension.count != second.extension.count
                    ? first.extension.count > second.extension.count
                    : first.extension < second.extension
            }

        if let dot = path.lastIndex(of: "."),
           let exact = entries.first(where: { $0.extension == path[dot...] }) {
            return exact.value
        }

        return entries.first { path.contains($0.extension) }?.value
    }
}
