import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Menu bar")
struct MenuBarTests {
    private func panel(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(MenuPanel(), h).inspect()
    }

    private func metWaterDays(_ count: Int) -> [HistoryEvent] {
        (0 ..< count).map { .done(.water, 8, at: Calendar.current.date(byAdding: .day, value: -$0, to: day(2026, 3, 3, 12))!) }
    }

    @Test func panelShowsTheGreeting() throws {
        let h = EngineHarness { $0.prefs.general.name = "Asha" }
        #expect(throws: Never.self) { try panel(h).find(text: h.engine.greeting) }
        #expect(throws: Never.self) { try panel(h).find(text: "Good morning, Asha") }
    }

    @Test func headerShowsTheStreakWhenThereIsOne() throws {
        let h = EngineHarness { $0.events = metWaterDays(3) }
        let header = try hosted(MenuHeader(), h).inspect()
        #expect(MenuFind.hasText(header, containing: "3-day streak"))
        #expect(throws: Never.self) { try header.find(text: h.engine.greeting) }
        #expect(try panel(h).findAll(MenuHeader.self).count == 1)
    }

    @Test func headerHidesTheStreakWithoutOne() throws {
        let header = try hosted(MenuHeader(), EngineHarness()).inspect()
        #expect(!MenuFind.hasText(header, containing: "-day streak"))
    }

    @Test func panelHidesTheStreakWithoutOne() throws {
        let h = EngineHarness()
        #expect(try !MenuFind.hasText(panel(h), containing: "-day streak"))
    }

    @Test func panelShowsACardForEachEnabledHabit() throws {
        let h = EngineHarness()
        #expect(try panel(h).findAll(HabitCard.self).count == 2)
        #expect(try panel(h).findAll(HabitCard.self).map { try $0.actualView().id } == [.water, .reading])
    }

    @Test func panelShowsASleepingRowForEachDisabledHabit() throws {
        let h = EngineHarness { $0.prefs.reading.enabled = false }
        let sut = try panel(h)
        #expect(sut.findAll(HabitCard.self).count == 1)
        #expect(sut.findAll(SleepingRow.self).count == 2)
        #expect(throws: Never.self) { try sut.find(text: "Reading is sleeping") }
        #expect(throws: Never.self) { try sut.find(text: "Meditation is sleeping") }
        #expect(Find.lacks(sut, text: "Water is sleeping"))
    }

    @Test func allEnabledMeansNoSleepingRow() throws {
        let h = EngineHarness { $0.prefs.meditation.enabled = true }
        let sut = try panel(h)
        #expect(sut.findAll(HabitCard.self).count == 3)
        #expect(sut.findAll(SleepingRow.self).isEmpty)
    }

    @Test func turnOnWakesTheSleepingMeditation() throws {
        let h = EngineHarness()
        try MenuFind.control(panel(h), "Turn on").tap()
        #expect(h.engine.data.prefs.meditation.enabled)
        #expect(h.store.prefs.meditation.enabled)
    }

    @Test func thirtyMinutesPausesForHalfAnHour() throws {
        let h = EngineHarness()
        try MenuFind.control(panel(h), "30 min").tap()
        #expect(h.engine.pausedUntil == day(2026, 3, 4, 10, 30))
    }

    @Test func oneHourPausesForAnHour() throws {
        let h = EngineHarness()
        try MenuFind.control(panel(h), "1 hour").tap()
        #expect(h.engine.pausedUntil == day(2026, 3, 4, 11))
    }

    @Test func restOfDayPausesUntilMidnight() throws {
        let h = EngineHarness()
        try MenuFind.control(panel(h), "Rest of day").tap()
        #expect(h.engine.pausedUntil == day(2026, 3, 5))
    }

    @Test func pauseChipsHaveAHint() throws {
        #expect(throws: Never.self) { try panel(EngineHarness()).find(text: "Take a break from reminders") }
    }

    @Test func pausedPanelShowsTheNapBanner() throws {
        let h = EngineHarness()
        h.engine.pause(hours: 1)
        let sut = try panel(h)
        let time = day(2026, 3, 4, 11).formatted(date: .omitted, time: .shortened)
        #expect(sut.findAll(NapBanner.self).count == 1)
        #expect(MenuFind.hasText(sut, containing: "Buddies are napping until"))
        #expect(MenuFind.hasText(sut, containing: time))
    }

    @Test func wakeUpResumes() throws {
        let h = EngineHarness()
        h.engine.pause(hours: 1)
        try MenuFind.control(panel(h), "Wake up").tap()
        #expect(h.engine.pausedUntil == nil)
    }

    @Test func noBannerWithoutAPause() throws {
        let sut = try panel(EngineHarness())
        #expect(sut.findAll(NapBanner.self).isEmpty)
        #expect(!MenuFind.hasText(sut, containing: "Buddies are napping"))
        #expect(Find.lacks(sut, text: "Wake up"))
    }

    @Test func settingsOpensSettings() throws {
        let h = EngineHarness()
        try Find.button(panel(h), label: "Settings").tap()
        #expect(h.presenter.calls.last == .showSettings)
    }

    @Test func reportsIsDisabled() throws {
        #expect(try Find.button(panel(EngineHarness()), label: "Reports").isDisabled())
    }

    @Test func quitIsThere() throws {
        #expect(throws: Never.self) { try MenuFind.control(panel(EngineHarness()), "Quit Sathi") }
    }

    @Test func footerShowsTheAppName() throws {
        let names = try MenuFind.texts(hosted(MenuFooter(), EngineHarness()).inspect())
        #expect(names.contains { $0 == "Sathi" || $0.hasPrefix("Sathi ") })
    }

    @Test func statusLabelShowsTheStatusText() throws {
        let h = EngineHarness()
        let sut = StatusLabel(status: h.engine.status)
        #expect(try sut.inspect().find(text: "2h 0m") != nil)
    }

    @Test func statusIconIsCachedPerLevel() {
        #expect(StatusIcon.image(level: 0.5) === StatusIcon.image(level: 0.5))
        #expect(StatusIcon.image(level: 0.5).isTemplate)
    }
}
