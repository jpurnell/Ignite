//
// String-EscapedForXML.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

public extension String {
    /// Escapes XML special characters for use outside CDATA sections.
    ///
    /// Replaces `&`, `<`, `>`, `"`, and `'` with their corresponding
    /// XML entity references. This is necessary for text content in
    /// RSS and Atom feed elements that are not wrapped in CDATA.
    func escapedForXML() -> String {
        self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

extension String {
    /// This string as one or more XML CDATA sections that together hold exactly this text.
    ///
    /// Nothing is escaped inside a CDATA section, and the only thing that ends one is
    /// `]]>`. Where the text contains that sequence the section is closed after `]]` and a
    /// new one opened before `>`, so a reader joins the pieces back into the original.
    /// - Returns: The text, wrapped in `<![CDATA[` … `]]>`.
    func wrappedInCDATA() -> String {
        "<![CDATA[" + replacing("]]>", with: "]]]]><![CDATA[>") + "]]>"
    }
}

