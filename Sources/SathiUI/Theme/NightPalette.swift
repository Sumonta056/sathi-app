import SathiCore
import SwiftUI

enum NightHex {
    static let calm: UInt32 = 0xA99CF5
    static let water: UInt32 = 0x4CC3F5
    static let cheek: UInt32 = 0xFF9FB8
    static let spark: UInt32 = 0xFFC94A
    static let trackerCoral: UInt32 = 0xFF8A80
    static let calmGround: UInt32 = 0x16142A
    static let text: UInt32 = 0xEEF2FA
    static let muted: UInt32 = 0x9AA6BF
    static let sprout: UInt32 = 0x5FD39A
    static let border: UInt32 = 0x263049
    static let trackerEvent: UInt32 = 0x7FB8FF
    static let trackerAway: UInt32 = 0x3A4458
}

enum Night {
    static let bg = Color(hex: 0x121826)
    static let sidebar = Color(hex: 0x0D1220)
    static let card = Color(hex: 0x1A2233)
    static let border = Color(hex: NightHex.border)
    static let divider = Color(hex: 0x222B40)
    static let text = Color(hex: NightHex.text)
    static let muted = Color(hex: NightHex.muted)
    static let label = Color(hex: 0x8C99B3)
    static let faint = Color(hex: 0x7784A0)
    static let water = Color(hex: NightHex.water)
    static let waterLine = Color(hex: 0x7FD3F5)
    static let reading = Color(hex: 0xF2A64A)
    static let calm = Color(hex: NightHex.calm)
    static let gym = Color(hex: 0xCDEF5A)
    static let sprout = Color(hex: NightHex.sprout)
    static let sproutLight = Color(hex: 0xA6EBC7)
    static let cheek = Color(hex: NightHex.cheek)
    static let spark = Color(hex: NightHex.spark)
    static let onAccent = Color(hex: 0x0D1220)
    static let switchOff = Color(hex: 0x3A4458)
    static let fieldBorder = Color(hex: 0x2C3650)
    static let chipText = Color(hex: 0xC9D2E3)
    static let navSelected = Color(hex: 0x1E2840)
    static let calmGround = Color(hex: NightHex.calmGround)
    static let quick = Color(hex: 0xFF9FB8)
    static let quickFill = Color(hex: 0x2A1C25)
    static let quickBorder = Color(hex: 0x4A2E3D)
    static let block = Color(hex: 0x5ED6C4)
    static let blockFill = Color(hex: 0x142A2A)
    static let blockBorder = Color(hex: 0x1F4744)
    static let tracker = Color(hex: NightHex.trackerCoral)
    static let trackerFill = Color(hex: 0x2E1A1C)
    static let trackerOnAccent = Color(hex: 0x2A0E0C)
    static let trackerSelectedText = Color(hex: 0xFFB3AB)
    static let trackerTile = tracker.opacity(0.14)
    static let trackerSelectedFill = tracker.opacity(0.16)
    static let trackerMenu = Color(hex: 0x1E2840)
    static let trackerMenuRow = Color(hex: 0x2A3550)
    static let trackerInset = Color(hex: 0x161D2C)
    static let trackerWell = Color(hex: 0x121826)
    static let trackerAway = Color(hex: NightHex.trackerAway)
    static let trackerNotLogged = Color(hex: 0x4A5570)
    static let trackerEvent = Color(hex: NightHex.trackerEvent)
    static let trackerRowSelected = Color(hex: 0x24304A)
    static let trackerNowBorder = Color(hex: 0x4A2A2C)
    static let trackerStopBorder = Color(hex: 0x5A3436)
    static let trackerNowText = Color(hex: 0xC9B9B9)

    static func category(_ hex: UInt32) -> Color { Color(hex: hex) }

    static func accent(_ id: HabitID) -> Color {
        switch id {
        case .water: water
        case .reading: reading
        case .meditation: calm
        case .gym: gym
        }
    }

    static func heroFill(_ id: HabitID) -> Color {
        switch id {
        case .water: Color(hex: 0x15263A)
        case .reading: Color(hex: 0x2A2219)
        case .meditation: Color(hex: 0x211F38)
        case .gym: Color(hex: 0x222A16)
        }
    }

    static func heroBorder(_ id: HabitID) -> Color {
        switch id {
        case .water: Color(hex: 0x1F3D5A)
        case .reading: Color(hex: 0x4A3720)
        case .meditation: Color(hex: 0x37335C)
        case .gym: Color(hex: 0x46561F)
        }
    }
}

