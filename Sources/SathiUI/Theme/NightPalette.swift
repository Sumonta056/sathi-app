import SathiCore
import SwiftUI

enum Night {
    static let bg = Color(hex: 0x121826)
    static let sidebar = Color(hex: 0x0D1220)
    static let card = Color(hex: 0x1A2233)
    static let border = Color(hex: 0x263049)
    static let divider = Color(hex: 0x222B40)
    static let text = Color(hex: 0xEEF2FA)
    static let muted = Color(hex: 0x9AA6BF)
    static let label = Color(hex: 0x8C99B3)
    static let faint = Color(hex: 0x7784A0)
    static let water = Color(hex: 0x4CC3F5)
    static let reading = Color(hex: 0xF2A64A)
    static let calm = Color(hex: 0xA99CF5)
    static let sprout = Color(hex: 0x5FD39A)
    static let cheek = Color(hex: 0xFF9FB8)
    static let spark = Color(hex: 0xFFC94A)
    static let onAccent = Color(hex: 0x0D1220)
    static let switchOff = Color(hex: 0x3A4458)
    static let fieldBorder = Color(hex: 0x2C3650)
    static let chipText = Color(hex: 0xC9D2E3)
    static let navSelected = Color(hex: 0x1E2840)
    static let calmGround = Color(hex: 0x16142A)

    static func accent(_ id: HabitID) -> Color {
        switch id {
        case .water: water
        case .reading: reading
        case .meditation: calm
        }
    }

    static func heroFill(_ id: HabitID) -> Color {
        switch id {
        case .water: Color(hex: 0x15263A)
        case .reading: Color(hex: 0x2A2219)
        case .meditation: Color(hex: 0x211F38)
        }
    }

    static func heroBorder(_ id: HabitID) -> Color {
        switch id {
        case .water: Color(hex: 0x1F3D5A)
        case .reading: Color(hex: 0x4A3720)
        case .meditation: Color(hex: 0x37335C)
        }
    }
}
