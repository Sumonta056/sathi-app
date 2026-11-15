import Foundation

extension TodoRules {
    package static func colorValue(_ hex: String) -> UInt32 {
        UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
    }
}
