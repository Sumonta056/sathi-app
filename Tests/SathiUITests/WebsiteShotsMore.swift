import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Website shots, newer views", .enabled(if: ShotFolder.path != nil))
struct WebsiteShotsMore {
    @Test func gymCorner() throws {
        let h = Shots.harness()
        h.showReminder(.gym)
        try Shots.save(GymInvite(level: .nudge), "gym-corner", h)
    }

    @Test func gymThanks() throws {
        let h = Shots.harness()
        h.engine.startSession(.gym)
        h.advance(minutes: 11)
        try Shots.save(CelebrateView(), "gym-thanks", h)
    }

    @Test func daySummary() throws {
        let h = Shots.harness(at: day(2026, 3, 26, 22)) {
            $0.events += [
                .done(.water, 4, at: day(2026, 3, 26, 15)),
                .done(.reading, 15, at: day(2026, 3, 26, 21, 30)),
                .done(.gym, 1, at: day(2026, 3, 26, 12)),
                .done(.gym, 1, at: day(2026, 3, 26, 14))
            ]
        }
        try Shots.save(DaySummaryCard(), "day-summary", h)
    }

    @Test func quickAdd() throws {
        let h = Shots.harness()
        let form = QuickAddForm(text: "Call mom", onClose: {})
            .modifier(CornerCard(width: UIMetrics.quickAddWidth, border: Night.quickBorder))
        try Shots.save(form, "quick-add", h)
    }

    @Test func quickPopup() throws {
        let item = QuickReminder(text: "Call mom", due: Shots.today, createdAt: day(2026, 3, 26, 9, 45))
        let h = Shots.harness { $0.live.quickReminders = [item] }
        try Shots.save(QuickPopup(id: item.id, level: .nudge), "quick-popup", h)
    }

    @Test func blockStart() throws {
        let h = Shots.harness()
        try Shots.save(BlockStartPopup(), "block-start", h)
    }

    @Test func blockPill() throws {
        let h = Shots.harness(at: Date.now.addingTimeInterval(-18 * 60), others: false)
        h.startBlock("Write the report", .minutes(30))
        h.advance(minutes: 18)
        try Shots.save(BlockWidget(), "block-pill", h)
    }

    @Test func blockDone() throws {
        let h = Shots.harness()
        h.startBlock("Write the report", .minutes(45))
        h.advance(minutes: 45)
        try Shots.save(BlockDonePopup(), "block-done", h)
    }

    @Test func blockSettings() throws {
        let h = Shots.harness()
        try Shots.save(SettingsView(tab: .timeBlocks).frame(height: UIMetrics.settingsSize.height), "block-settings", h)
    }
}
