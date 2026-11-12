import Foundation

package struct ActivityCategory: Codable, Equatable, Hashable, Identifiable, Sendable {
    package var name: String
    package var colorHex: UInt32

    package init(name: String, colorHex: UInt32) {
        self.name = name
        self.colorHex = colorHex
    }

    package var id: String { name }

    package static let defaults: [ActivityCategory] = [
        ActivityCategory(name: "Coding", colorHex: 0x4CC3F5),
        ActivityCategory(name: "Meeting", colorHex: 0xC9B8FF),
        ActivityCategory(name: "Cefalo Meetings", colorHex: 0x7FB8FF),
        ActivityCategory(name: "Review", colorHex: 0xF2A64A),
        ActivityCategory(name: "Learning", colorHex: 0x5FD39A),
        ActivityCategory(name: "Email", colorHex: 0xFF9FB8)
    ]

    package static let palette: [UInt32] = [
        0x4CC3F5, 0xA99CF5, 0x7FB8FF, 0xF2A64A, 0x5FD39A, 0xFF9FB8, 0xFFC94A, 0x5ED6C4, 0xCDEF5A, 0xC9B8FF, 0x4C8BF5, 0xFF7A6B
    ]

    package static func buddy(_ id: HabitID) -> ActivityCategory {
        switch id {
        case .water: return ActivityCategory(name: "Water", colorHex: 0x4CC3F5)
        case .reading: return ActivityCategory(name: "Reading", colorHex: 0xF2A64A)
        case .meditation: return ActivityCategory(name: "Meditation", colorHex: 0xA99CF5)
        case .gym: return ActivityCategory(name: "Gym", colorHex: 0xCDEF5A)
        }
    }
}
