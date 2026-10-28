import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Day summary card")
struct DaySummaryCardTests {
    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try DaySummaryCard().environmentObject(h.engine).inspect()
    }

    @Test func showsFourRows() throws {
        let sut = try card(EngineHarness())
        for name in ["FOTA · WATER", "BOI · READING", "SHANTI · MEDITATION", "SHOKTI · GYM"] {
            #expect(throws: Never.self) { try sut.find(text: name) }
        }
    }

    @Test func aHabitThatIsOffSaysOff() throws {
        let sut = try card(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: "Off") }
    }

    @Test func aDayOffWithTheGoalNotMetSaysDayOff() throws {
        let h = EngineHarness {
            var d = $0.prefs.days(.water)
            d.daysOff.insert(DayKey(day(2026, 3, 4), calendar: .current))
            $0.prefs.setDays(.water, d)
        }
        #expect(throws: Never.self) { try card(h).find(text: "Day off") }
    }

    @Test func progressShowsTheRowsOwnValues() throws {
        let h = EngineHarness {
            $0.prefs.water.dailyGoalGlasses = 8
            $0.events = [.done(.water, 6, at: day(2026, 3, 4, 8))]
        }
        let sut = try card(h)
        #expect(throws: Never.self) { try sut.find(text: "6") }
        #expect(throws: Never.self) { try sut.find(text: "of 8 glasses") }
    }

    @Test func titleFollowsTheVerdict() throws {
        let none = try card(EngineHarness())
        #expect(throws: Never.self) { try none.find(text: "Rest well, Mridul.") }
        let rest = try card(EngineHarness {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
        })
        #expect(throws: Never.self) { try rest.find(text: "Enjoy your rest, Mridul.") }
    }

    @Test func goodNightClosesTheSummary() throws {
        let h = EngineHarness()
        try card(h).find(button: "Good night").tap()
        #expect(h.presenter.calls.last == .closeDaySummary)
    }

    @Test func closeButtonClosesTheSummary() throws {
        let h = EngineHarness()
        try Find.button(card(h), label: "Close").tap()
        #expect(h.presenter.calls.last == .closeDaySummary)
    }

    @Test func rowsUseStillBuddies() throws {
        let sut = try card(EngineHarness())
        #expect((try? sut.find(BuddyView.self)) == nil)
        #expect((try? sut.find(BobbingBuddy.self)) == nil)
    }
}
