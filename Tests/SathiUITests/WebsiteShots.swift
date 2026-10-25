import AppKit
import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

enum ShotFolder {
    static let path = ProcessInfo.processInfo.environment["SATHI_SHOTS"]
}

@MainActor
@Suite("Website shots", .enabled(if: ShotFolder.path != nil))
struct WebsiteShots {
    private func sampleEvents() -> [HistoryEvent] {
        let water: [Double] = [8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 8, 8, 5, 8, 8, 8, 6, 8, 8, 3, 8, 8, 8, 7, 8]
        let reading: [Double] = [15, 20, 15, 0, 15, 30, 15, 15, 10, 15, 15, 20, 15, 0, 15, 15, 20, 15, 5, 15, 15, 0, 15, 15, 15]
        let calm: [Double] = [10, 10, 5, 10, 10, 0, 10, 10, 10, 5, 10, 10, 0, 10, 10, 10, 10, 5, 10, 10, 0, 10, 10, 10, 10]
        var events: [HistoryEvent] = []
        for back in 1 ... water.count {
            let date = Calendar.current.date(byAdding: .day, value: -back, to: day(2026, 3, 26, 12))!
            events.append(.done(.water, water[back - 1], at: date))
            if reading[back - 1] > 0 { events.append(.done(.reading, reading[back - 1], at: date)) }
            if calm[back - 1] > 0 { events.append(.done(.meditation, calm[back - 1], at: date)) }
        }
        events.append(.done(.water, 4, at: day(2026, 3, 26, 9, 40)))
        events.append(.done(.meditation, 10, at: day(2026, 3, 26, 8, 10)))
        return events
    }

    private func harness(at start: Date = day(2026, 3, 26, 10, 30), others: Bool = true) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.water.enabled = others
            $0.prefs.general.name = "Alex"
            $0.prefs.meditation.enabled = others
            $0.events = sampleEvents()
        }
    }

    private func save(_ view: some View, _ name: String, _ h: EngineHarness) throws {
        let host = NSHostingView(rootView: view.environmentObject(h.engine).environment(\.colorScheme, .dark))
        host.frame = CGRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        host.display()
        let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        let png = try #require(rep.representation(using: .png, properties: [:]))
        let url = try URL(fileURLWithPath: #require(ShotFolder.path)).appendingPathComponent("\(name).png")
        try png.write(to: url)
    }

    @Test func menuBar() throws {
        let h = harness()
        try save(MenuPanel(), "menu-bar", h)
    }

    @Test func settings() throws {
        let h = harness()
        try save(SettingsView(tab: .habit(.water)).frame(height: UIMetrics.settingsSize.height), "settings", h)
    }

    @Test func reports() throws {
        let h = harness()
        try save(ReportsView().frame(width: UIMetrics.settingsSize.width, height: UIMetrics.settingsSize.height), "reports", h)
    }

    @Test func waterBubble() throws {
        let h = harness()
        h.showReminder(.water)
        try save(BubbleView(id: .water, level: .nudge), "water-bubble", h)
    }

    @Test func readingCorner() throws {
        let h = harness()
        try save(ReadingInvite(level: .nudge), "reading-corner", h)
    }

    @Test func meditation() throws {
        let h = harness()
        try save(BubbleView(id: .meditation, level: .nudge), "meditation", h)
    }

    @Test func waterNudgy() throws {
        let h = harness()
        h.showReminder(.water)
        h.engine.snooze(.water)
        try save(BubbleView(id: .water, level: .persist), "water-nudgy", h)
    }

    @Test func waterLock() throws {
        let h = harness()
        h.showReminder(.water)
        try save(LockView(id: .water).frame(width: 1280, height: 800), "water-lock", h)
    }

    @Test func waterThanks() throws {
        let h = harness()
        h.showReminder(.water)
        h.engine.logWater(1)
        try save(CelebrateView(), "water-thanks", h)
    }

    @Test func readingTimer() throws {
        let h = harness(at: Date.now.addingTimeInterval(-360), others: false)
        h.engine.startReading()
        h.advance(minutes: 6)
        try save(ReadingTimerPill(), "reading-timer", h)
    }

    @Test func readingDone() throws {
        let h = harness()
        h.engine.startReading()
        h.advance(minutes: 16)
        try save(CelebrateView(), "reading-done", h)
    }

    @Test func readingSnoozed() throws {
        let h = harness()
        try save(SnoozedNote(id: .reading, until: day(2026, 3, 26, 22, 5)), "reading-snoozed", h)
    }

    @Test func breathe() throws {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 1)
        try save(BreatheView(), "meditation-breathe", h)
    }

    @Test func meditationThanks() throws {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 6)
        try save(CelebrateView(), "meditation-thanks", h)
    }
}
