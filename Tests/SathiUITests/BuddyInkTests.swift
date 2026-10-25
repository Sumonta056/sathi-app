@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Buddy ink")
struct BuddyInkTests {
    private static let table: [(String, Color, UInt32)] = [
        ("line", BuddyInk.line, 0x0D1B2A),
        ("water", BuddyInk.water, 0x1FA8E6),
        ("waterDeep", BuddyInk.waterDeep, 0x0B5F9E),
        ("waterPale", BuddyInk.waterPale, 0xDCF2FC),
        ("waterMid", BuddyInk.waterMid, 0x7FD3F5),
        ("waterGlass", BuddyInk.waterGlass, 0xEEF8FD),
        ("waterDrained", BuddyInk.waterDrained, 0xBFE8FA),
        ("outline", BuddyInk.outline, 0x0B4F86),
        ("drip", BuddyInk.drip, 0x8FD8F7),
        ("cover", BuddyInk.cover, 0xF2A33A),
        ("spine", BuddyInk.spine, 0xD9822B),
        ("pages", BuddyInk.pages, 0xFFF6E2),
        ("bookLine", BuddyInk.bookLine, 0x7A420F),
        ("ribbon", BuddyInk.ribbon, 0xE0473C),
        ("cheek", BuddyInk.cheek, 0xFF9FB8),
        ("spark", BuddyInk.spark, 0xFFC94A)
    ]

    @Test func everyArtColorKeepsItsHex() {
        for (name, color, hex) in Self.table {
            #expect(RGB(color).matches(RGB(Color(hex: hex))), "BuddyInk.\(name) is not \(String(hex, radix: 16))")
        }
    }

    @Test func tableCoversSixteenColors() {
        #expect(Set(Self.table.map(\.0)).count == 16)
    }
}
