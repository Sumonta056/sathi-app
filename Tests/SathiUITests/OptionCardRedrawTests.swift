import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Option card redraw", .serialized)
struct OptionCardRedrawTests {
    @Test func waterIntervalChipRedraws() {
        expectRedraw(WaterSettingsTab(), from: { $0.prefs.water.intervalMinutes = 120 }, to: { $0.prefs.water.intervalMinutes = 60 })
    }

    @Test func waterStrictnessRedraws() {
        expectRedraw(WaterSettingsTab(), from: { $0.prefs.water.strictness = .friendly }, to: { $0.prefs.water.strictness = .strict })
    }

    @Test func readingStrictnessRedraws() {
        expectRedraw(ReadingSettingsTab(), from: { $0.prefs.reading.strictness = .friendly }, to: { $0.prefs.reading.strictness = .persistent })
    }

    @Test func readingStyleRedraws() {
        expectRedraw(ReadingSettingsTab(), from: { $0.prefs.reading.reminderStyle = .corner }, to: { $0.prefs.reading.reminderStyle = .focus })
    }

    @Test func meditationStrictnessRedraws() {
        expectRedraw(
            MeditationSettingsTab(),
            from: { $0.prefs.meditation.enabled = true; $0.prefs.meditation.strictness = .persistent },
            to: { $0.prefs.meditation.strictness = .strict }
        )
    }

    @Test func breathingPatternRedraws() {
        expectRedraw(
            MeditationSettingsTab(),
            from: { $0.prefs.meditation.enabled = true; $0.prefs.meditation.style = .box },
            to: { $0.prefs.meditation.style = .even }
        )
    }

    @Test func gymStrictnessRedraws() {
        expectRedraw(
            GymSettingsTab(),
            from: { $0.prefs.gym.enabled = true; $0.prefs.gym.strictness = .persistent },
            to: { $0.prefs.gym.strictness = .friendly }
        )
    }

    private func expectRedraw(
        _ view: some View,
        from start: @escaping (inout Persisted) -> Void,
        to change: @escaping (inout Persisted) -> Void
    ) {
        let h = EngineHarness(configure: start)
        let live = Snapshot.host(view, h)
        let before = Snapshot.png(live)
        change(&h.engine.data)
        let after = Snapshot.png(live)
        let fresh = Snapshot.png(Snapshot.host(view, EngineHarness { start(&$0); change(&$0) }))
        #expect(before != fresh)
        #expect(after == fresh)
    }
}

@MainActor
enum Snapshot {
    private static let size = NSSize(width: 700, height: 1600)

    static func host(_ view: some View, _ h: EngineHarness) -> NSView {
        let host = NSHostingView(rootView: hosted(view, h))
        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        return host
    }

    static func png(_ v: NSView) -> Data {
        RunLoop.main.run(mode: .default, before: .distantPast)
        v.layoutSubtreeIfNeeded()
        guard let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) else { return Data() }
        v.cacheDisplay(in: v.bounds, to: rep)
        return rep.representation(using: .png, properties: [:]) ?? Data()
    }
}
