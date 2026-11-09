import Foundation

package enum KeyModifier: String, Codable, CaseIterable, Sendable {
    case control
    case option
    case shift
    case command
}

package struct KeyShortcut: Codable, Equatable, Hashable, Sendable {
    package var keyCode: UInt32
    package var modifiers: Set<KeyModifier>
    package var keyName: String

    package init(keyCode: UInt32, modifiers: Set<KeyModifier>, keyName: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyName = keyName
    }

    package static let trackerDefault = KeyShortcut(
        keyCode: Limits.spaceKeyCode,
        modifiers: [.option, .command],
        keyName: Limits.spaceKeyName
    )

    package var orderedModifiers: [KeyModifier] { KeyModifier.allCases.filter(modifiers.contains) }

    enum CodingKeys: String, CodingKey {
        case keyCode, modifiers, keyName
    }

    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try c.decode(UInt32.self, forKey: .keyCode)
        modifiers = try c.knownSet(.modifiers, or: [], keepsEmpty: true)
        keyName = try c.decode(String.self, forKey: .keyName)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(keyCode, forKey: .keyCode)
        try c.encode(orderedModifiers, forKey: .modifiers)
        try c.encode(keyName, forKey: .keyName)
    }
}
