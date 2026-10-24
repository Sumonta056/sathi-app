import SathiCore
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Night palette")
struct NightPaletteTests {
    private static let grounds: [(String, Color)] = [("bg", Night.bg), ("sidebar", Night.sidebar), ("card", Night.card)]

    private func expectReadable(_ fg: Color, on bg: Color, _ name: String) {
        let ratio = Contrast.ratio(fg, bg)
        #expect(ratio >= 4.5, "\(name) contrast \(ratio) is below 4.5")
    }

    @Test func textColorsReadOnEveryGround() {
        let fgs: [(String, Color)] = [
            ("text", Night.text), ("muted", Night.muted), ("label", Night.label), ("chipText", Night.chipText)
        ]
        for (f, fg) in fgs {
            for (g, bg) in Self.grounds {
                expectReadable(fg, on: bg, "\(f) on \(g)")
            }
        }
    }

    @Test func faintReadsOnBackgroundAndSidebar() {
        expectReadable(Night.faint, on: Night.bg, "faint on bg")
        expectReadable(Night.faint, on: Night.sidebar, "faint on sidebar")
    }

    @Test(arguments: HabitID.allCases)
    func accentReadsOnEveryGround(_ id: HabitID) {
        for (g, bg) in Self.grounds {
            expectReadable(Night.accent(id), on: bg, "\(id) accent on \(g)")
        }
    }

    @Test func sproutReadsOnEveryGround() {
        for (g, bg) in Self.grounds {
            expectReadable(Night.sprout, on: bg, "sprout on \(g)")
        }
    }

    @Test(arguments: HabitID.allCases)
    func onAccentReadsOnAccent(_ id: HabitID) {
        expectReadable(Night.onAccent, on: Night.accent(id), "onAccent on \(id) accent")
    }

    @Test func onAccentReadsOnSprout() {
        expectReadable(Night.onAccent, on: Night.sprout, "onAccent on sprout")
    }

    @Test(arguments: HabitID.allCases)
    func mutedReadsOnHeroFill(_ id: HabitID) {
        expectReadable(Night.muted, on: Night.heroFill(id), "muted on \(id) hero fill")
    }

    @Test(arguments: [
        (HabitID.water, UInt32(0x4CC3F5), UInt32(0x15263A), UInt32(0x1F3D5A)),
        (HabitID.reading, UInt32(0xF2A64A), UInt32(0x2A2219), UInt32(0x4A3720)),
        (HabitID.meditation, UInt32(0xA99CF5), UInt32(0x211F38), UInt32(0x37335C)),
    ])
    func habitColorsMatchTheDesign(_ id: HabitID, _ accent: UInt32, _ fill: UInt32, _ border: UInt32) {
        #expect(RGB(Night.accent(id)).matches(RGB(hex: accent)))
        #expect(RGB(Night.heroFill(id)).matches(RGB(hex: fill)))
        #expect(RGB(Night.heroBorder(id)).matches(RGB(hex: border)))
    }

    @Test func accentsAreTheNamedHabitColors() {
        #expect(RGB(Night.accent(.water)).matches(RGB(Night.water)))
        #expect(RGB(Night.accent(.reading)).matches(RGB(Night.reading)))
        #expect(RGB(Night.accent(.meditation)).matches(RGB(Night.calm)))
    }
}
