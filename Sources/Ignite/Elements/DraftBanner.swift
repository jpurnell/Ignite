//
//  DraftBanner.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

import Foundation

/// A visual banner indicating draft, scheduled, or expired content status.
/// Renders a fixed-position bar at the top of the page with a status label.
/// Renders nothing for published content.
public struct DraftBanner: HTML {
    /// The content and behavior of this HTML.
    public var body: some HTML { self }

    /// The standard set of control attributes for HTML elements.
    public var attributes = CoreAttributes()

    /// Whether this HTML belongs to the framework.
    public var isPrimitive: Bool { true }

    private let status: ContentStatus

    /// Creates a draft banner for the given content status.
    /// - Parameter status: The content status to display.
    public init(status: ContentStatus) {
        self.status = status
    }

    public func markup() -> Markup {
        let (label, color): (String, String) = switch status {
        case .draft:
            ("DRAFT", "#dc3545")
        case .scheduled:
            ("SCHEDULED", "#fd7e14")
        case .expired:
            ("EXPIRED", "#6c757d")
        case .published:
            ("", "")
        }

        guard !label.isEmpty else { return Markup("") }

        return Markup("""
        <div style="position:fixed;top:0;left:0;right:0;z-index:9999;\
        background:\(color);color:white;text-align:center;padding:4px 0;\
        font-size:12px;font-weight:bold;letter-spacing:1px;opacity:0.9;">\
        \(label) \u{2014} This content will not appear in production builds\
        </div>\
        <div style="height:28px;"></div>
        """)
    }
}
