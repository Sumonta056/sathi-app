import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker settings page")
struct TrackerSettingsPageTests {
    private func page(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TrackerSettingsPage(), h).inspect()
    }

    private func on() -> EngineHarness { EngineHarness { $0.prefs.tracker.isOn = true } }

    private func tap(_ sut: InspectableView<some BaseViewType>, _ id: String) throws {
        let view = try sut.find(viewWithAccessibilityIdentifier: id)
        if let b = try? view.button() { try b.tap() } else { try view.find(ViewType.Button.self, relation: .parent).tap() }
    }

    @Test func hasEveryRowOfRule39() throws {
        let sut = try page(EngineHarness())
        let texts: [String] = [
            Copywriter.trackerOnLabel, Copywriter.trackerHours, Copywriter.trackerDays,
            Copywriter.trackerAskEvery, Copywriter.trackerUsualLength, Copywriter.trackerAwayAfter,
            Copywriter.trackerCategories.uppercased(), Copywriter.trackerCalendar.uppercased(), Copywriter.trackerShortcutLabel,
            Copywriter.trackerEndOfDayLabel, Copywriter.trackerSoundLabel
        ]
        for t in texts {
            _ = try sut.find(text: t)
        }
    }

    @Test func askEveryChipSetsPrefs() throws {
        let h = on()
        try tap(page(h), "settings.tracker.ask.30")
        #expect(h.store.prefs.tracker.askEveryMinutes == 30)
    }

    @Test func askEveryChipMovesTheAskTimeOfTheRunningActivity() throws {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        h.engine.startActivity(ActivityDraft(text: "Spec", length: .minutes(30)))
        h.advance(minutes: 5)
        try tap(page(h), "settings.tracker.ask.10")
        #expect(h.engine.runningActivity?.askAt == day(2026, 3, 4, 10, 10))
    }

    @Test func awayAfterChipSetsPrefs() throws {
        let h = on()
        try tap(page(h), "settings.tracker.idle.60")
        #expect(h.store.prefs.tracker.idleMinutes == 60)
    }

    @Test func usualLengthChipSetsPrefs() throws {
        let h = on()
        try tap(page(h), "settings.tracker.length.60")
        #expect(h.store.prefs.tracker.usualLength == .minutes(60))
    }

    @Test func weekdayChipToggles() throws {
        let h = on()
        try tap(page(h), "settings.tracker.day.saturday")
        #expect(h.store.prefs.tracker.weekdays.contains(.saturday))
    }

    @Test func shortcutShowsDefault() throws {
        _ = try page(EngineHarness()).find(text: "⌃⌥⌘Space")
    }

    @Test func calendarRowsRenderWithNoReadableCalendars() throws {
        let h = EngineHarness { $0.prefs.tracker.readsEvents = true }
        h.calendarWriter.readable = []
        let sut = try page(h)
        _ = try sut.find(text: Copywriter.trackerReadCalendarsHint)
        #expect(h.engine.readableCalendarChoices().isEmpty)
    }

    @Test func deniedCalendarShowsOpenSettings() throws {
        let h = EngineHarness()
        h.calendarWriter.accessValue = .denied
        h.engine.refreshCalendarAccess()
        _ = try page(h).find(viewWithAccessibilityIdentifier: "settings.tracker.access.open")
    }

    @Test func offTrackerKeepsPageVisible() throws {
        _ = try page(EngineHarness { $0.prefs.tracker.isOn = false }).find(text: Copywriter.trackerWhenToAsk.uppercased())
    }

    private func eventsHarness(_ access: CalendarAccess) -> EngineHarness {
        let h = EngineHarness { $0.prefs.tracker.isOn = true; $0.prefs.tracker.readsEvents = true }
        h.calendarWriter.accessValue = access
        h.engine.refreshCalendarAccess()
        return h
    }

    @Test(arguments: [CalendarAccess.denied, .notAsked])
    func eventsListNeedsAccessWhenNotGranted(_ access: CalendarAccess) throws {
        let sut = try hosted(TrackerEventsCard(), eventsHarness(access)).inspect()
        _ = try sut.find(text: Copywriter.blockSettingsNeedsAccess)
        #expect(throws: (any Error).self) { try sut.find(text: TrackerCalendarList.emptyText) }
    }

    @Test func eventsListSaysNoCalendarsWhenAllowedAndEmpty() throws {
        let h = eventsHarness(.allowed)
        h.calendarWriter.readable = []
        let sut = try hosted(TrackerEventsCard(), h).inspect()
        _ = try sut.find(text: TrackerCalendarList.emptyText)
    }
}
