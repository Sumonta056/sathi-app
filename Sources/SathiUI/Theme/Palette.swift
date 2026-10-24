import SathiCore
import SwiftUI

enum Palette {
    static let ink = Color(hex: 0x0D1B2A)
    static let ink2 = Color(hex: 0x3A4D60)
    static let muted = Color(hex: 0x566A7E)
    static let card = Color(hex: 0xF8FBFD)

    static let water = Color(hex: 0x1FA8E6)
    static let waterDeep = Color(hex: 0x0B5F9E)
    static let waterPale = Color(hex: 0xDCF2FC)
    static let waterMid = Color(hex: 0x7FD3F5)
    static let waterGlass = Color(hex: 0xEEF8FD)
    static let waterDrained = Color(hex: 0xBFE8FA)
    static let outline = Color(hex: 0x0B4F86)
    static let drip = Color(hex: 0x8FD8F7)

    static let book = Color(hex: 0xE0902A)
    static let bookDeep = Color(hex: 0x8A4B12)
    static let bookCard = Color(hex: 0xFFF8EC)
    static let cover = Color(hex: 0xF2A33A)
    static let spine = Color(hex: 0xD9822B)
    static let pages = Color(hex: 0xFFF6E2)
    static let bookLine = Color(hex: 0x7A420F)
    static let ribbon = Color(hex: 0xE0473C)
    static let paper = Color(hex: 0xFFFAF1)

    static let go = Color(hex: 0x178A4F)
    static let cheek = Color(hex: 0xFF9FB8)
    static let spark = Color(hex: 0xFFC94A)
    static let night = Color(hex: 0x041A30)
    static let danger = Color(hex: 0xFFD2C2)
    static let lockBody = Color(hex: 0xCFE3F2)
    static let lockHint = Color(hex: 0xA9C7DD)

    static func accent(_ id: HabitID) -> Color {
        switch id {
        case .water: return water
        case .reading: return book
        }
    }

    static func deep(_ id: HabitID) -> Color {
        switch id {
        case .water: return waterDeep
        case .reading: return bookDeep
        }
    }
}
