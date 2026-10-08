//
// CustomAction.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

/// Allows the user to inject hand-written JavaScript into an event.
///
/// The code is JavaScript and is used as you wrote it. When it is placed into an event
/// attribute such as `onclick`, any double quote in it is written as `&quot;`, so it
/// cannot end the attribute; you do not need to do that yourself. To put a Swift string
/// into your code as a JavaScript string, use `javaScriptStringLiteral()`.
public struct CustomAction: Action {
    /// The JavaScript code to execute.
    var code: String

    /// Creates a new CustomAction action from the provided JavaScript code.
    /// - Parameter code: The code to execute.
    public init(_ code: String) {
        self.code = code
    }

    /// Returns the JavaScript this action was created with, unchanged.
    /// - Returns: The JavaScript for this action.
    public func compile() -> String {
        code
    }
}
