//
//  ValidationMode.swift
//  Ignite
//  https://www.github.com/twostraws/Ignite
//  See LICENSE for license information.
//

/// Controls how validation findings affect the build.
public enum ValidationMode: Sendable {
    case disabled
    case warn
    case strict
}
