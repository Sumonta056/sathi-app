import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Website shots", .enabled(if: ShotFolder.path != nil))
struct WebsiteShots {
    private func harness(at start: Date = Shots.today, others: Bool = true) -> EngineHarness {
        Shots.harness(at: start, others: others)
    }

    private func save(_ view: some View, _ name: String, _ h: EngineHarness) throws {
        try Shots.save(view, name, h)
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
        h.showReminder(.reading)
        try save(ReadingInvite(level: .nudge), "reading-corner", h)
    }

    @Test func meditation() throws {
        let h = harness()
        h.showReminder(.meditation)
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
