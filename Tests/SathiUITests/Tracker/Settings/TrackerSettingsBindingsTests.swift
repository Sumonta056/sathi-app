import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Tracker settings bindings")
struct TrackerSettingsBindingsTests {
    @Test func hoursWeekdaysAndChipsWritePrefs() {
        let h = EngineHarness()
        let e = h.engine
        e.trackerOn.wrappedValue = true
        e.trackerStartMinutes.wrappedValue = 600
        e.trackerEndMinutes.wrappedValue = 1020
        e.trackerAskEvery.wrappedValue = 30
        e.trackerIdle.wrappedValue = 20
        e.trackerUsualLength.wrappedValue = .open
        e.trackerWeekdays.wrappedValue = [.monday]
        let t = h.store.prefs.tracker
        #expect(t.isOn && t.startMinutes == 600 && t.endMinutes == 1020)
        #expect(t.askEveryMinutes == 30 && t.idleMinutes == 20 && t.usualLength == .open)
        #expect(t.weekdays == [.monday])
    }

    @Test func askEveryChangeMovesTheAskTimeOfTheRunningActivity() {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        h.engine.startActivity(ActivityDraft(text: "Spec", length: .minutes(30)))
        h.advance(minutes: 5)
        h.engine.trackerAskEvery.wrappedValue = 10
        #expect(h.store.prefs.tracker.askEveryMinutes == 10)
        #expect(h.engine.runningActivity?.askAt == day(2026, 3, 4, 10, 10))
    }

    @Test func lastWeekdayStays() {
        let h = EngineHarness { $0.prefs.tracker.weekdays = [.friday] }
        h.engine.toggleTrackerWeekday(.friday)
        #expect(h.engine.data.prefs.tracker.weekdays == [.friday])
        h.engine.toggleTrackerWeekday(.monday)
        #expect(h.engine.data.prefs.tracker.weekdays == [.friday, .monday])
    }

    @Test func switchesWritePrefs() {
        let h = EngineHarness()
        let e = h.engine
        e.trackerCalendarOnByDefault.wrappedValue = true
        e.trackerEndOfDay.wrappedValue = false
        e.trackerSound.wrappedValue = false
        e.trackerReadsEvents.wrappedValue = true
        e.trackerEventMode.wrappedValue = .askFirst
        e.trackerShortcut.wrappedValue = KeyShortcut(keyCode: 40, modifiers: [.control, .shift], keyName: "K")
        let t = h.engine.data.prefs.tracker
        #expect(t.calendarOnByDefault && !t.endOfDayOn && !t.playsSound && t.readsEvents)
        #expect(t.eventMode == .askFirst)
        #expect(t.shortcut.keyName == "K")
    }

    @Test func readCalendarTickToggles() {
        let h = EngineHarness()
        h.engine.toggleReadCalendar("work")
        h.engine.toggleReadCalendar("home")
        h.engine.toggleReadCalendar("work")
        #expect(h.engine.data.prefs.tracker.readCalendarIDs == ["home"])
    }

    @Test func categoryForCalendarMapsAndClears() {
        let h = EngineHarness()
        h.engine.setCategory(forCalendar: "work", to: "Review")
        #expect(h.engine.data.prefs.tracker.categoryByCalendar["work"] == "Review")
        h.engine.setCategory(forCalendar: "work", to: nil)
        #expect(h.engine.data.prefs.tracker.categoryByCalendar["work"] == nil)
    }

    @Test func daysOffAddAndRemove() {
        let h = EngineHarness()
        let d = key(2026, 3, 10)
        h.engine.addTrackerDayOff(d)
        #expect(h.engine.data.prefs.tracker.daysOff == [d])
        #expect(h.engine.upcomingTrackerDaysOff() == [d])
        h.engine.removeTrackerDayOff(d)
        #expect(h.engine.data.prefs.tracker.daysOff.isEmpty)
    }

    @Test func newCategoryColorCyclesThePalette() {
        let h = EngineHarness()
        #expect(ActivityCategory.palette.contains(h.engine.nextCategoryColor()))
    }
}
