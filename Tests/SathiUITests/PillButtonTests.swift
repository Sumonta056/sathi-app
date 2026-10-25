import AppKit
@testable import SathiUI
import SwiftUI
import Testing

private struct RGBA {
    let r: Double
    let g: Double
    let b: Double
    let a: Double

    init(_ color: Color) {
        let c = NSColor(color).usingColorSpace(.sRGB) ?? .clear
        r = Double(c.redComponent)
        g = Double(c.greenComponent)
        b = Double(c.blueComponent)
        a = Double(c.alphaComponent)
    }

    func matches(_ o: RGBA) -> Bool {
        let t = 1.0 / 255
        return abs(r - o.r) <= t && abs(g - o.g) <= t && abs(b - o.b) <= t && abs(a - o.a) <= t
    }
}

@MainActor
@Suite("Pill button")
struct PillButtonTests {
    private let ghostFill = Night.text.opacity(0.08)

    private func expectPair(_ kind: PillButton.Kind, fg: Color, bg: Color) {
        let pair = PillButton.colors(kind)
        #expect(RGBA(pair.fg).matches(RGBA(fg)), "\(kind) foreground")
        #expect(RGBA(pair.bg).matches(RGBA(bg)), "\(kind) background")
    }

    @Test func primaryIsDarkTextOnSprout() {
        expectPair(.primary, fg: Night.onAccent, bg: Night.sprout)
    }

    @Test func ghostIsTextOnAFaintTextFill() {
        expectPair(.ghost, fg: Night.text, bg: ghostFill)
    }

    @Test func onDarkIsDarkTextOnWater() {
        expectPair(.onDark, fg: Night.onAccent, bg: Night.water)
    }

    @Test func dangerIsCheekOnAFaintTextFill() {
        expectPair(.danger, fg: Night.cheek, bg: ghostFill)
    }
}
