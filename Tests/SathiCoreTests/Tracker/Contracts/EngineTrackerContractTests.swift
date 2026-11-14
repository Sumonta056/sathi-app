import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker contract")
struct EngineTrackerContractTests {
    @Test func aDefaultEngineHasTheTrackerOffAndShowsNoTrackerWindow() {
        let h = EngineHarness.quiet()
        h.advance(minutes: 600)
        #expect(!h.engine.data.prefs.tracker.isOn)
        #expect(h.engine.runningActivity == nil)
        #expect(h.presenter.trackerCalls.isEmpty)
        #expect(h.presence.starts == 0)
        #expect(h.hotkeys.registered.isEmpty)
        #expect(h.activities.saves == 0)
    }

    @Test func trackerHarnessTurnsTheTrackerOnWithBuddiesQuiet() {
        let h = EngineHarness.tracker()
        #expect(h.engine.data.prefs.tracker.isOn)
        #expect(!h.engine.data.prefs.water.enabled)
    }

    @Test func restartKeepsTheSameActivityStore() {
        let h = EngineHarness.tracker()
        let again = EngineHarness.restartedTracker(from: h, at: day(2026, 3, 4, 11))
        #expect(again.activities === h.activities)
        #expect(again.engine.data.prefs.tracker.isOn)
    }

    @Test func categoriesCanBeAddedRenamedRecoloredAndDeleted() {
        let h = EngineHarness.tracker()
        #expect(h.engine.addActivityCategory("Deep work", colorHex: 0x112233))
        #expect(!h.engine.addActivityCategory("deep work", colorHex: 0x112233))
        #expect(h.engine.renameActivityCategory("Deep work", to: "Focus"))
        h.engine.setActivityCategoryColor("Focus", colorHex: 0x445566)
        #expect(h.store.prefs.tracker.categories.last == ActivityCategory(name: "Focus", colorHex: 0x445566))
        h.engine.deleteActivityCategory("Focus")
        #expect(h.store.prefs.tracker.categories == ActivityCategory.defaults)
    }

    @Test func fakePresenceSendsEventsToItsListener() {
        let p = FakePresenceMonitor()
        var got: [PresenceEvent] = []
        p.start { got.append($0) }
        p.send(.locked)
        p.stop()
        p.send(.unlocked)
        #expect(got == [.locked])
        p.idleSeconds = 90
        #expect(p.secondsSinceLastInput() == 90)
        #expect(p.idleReads == 1)
    }

    @Test func spyHotkeyCallsBackOnPress() {
        let k = SpyHotkeyRegistrar()
        var presses = 0
        #expect(k.register(TrackerPrefs().shortcut) { presses += 1 })
        k.press()
        k.unregister()
        k.press()
        #expect(presses == 1)
        #expect(k.unregisters == 1)
    }

    @Test func spyCalendarReturnsOnlyTickedEventsInTheRange() {
        let w = SpyCalendarWriter()
        let start = day(2026, 11, 9, 14)
        w.eventsValue = [
            CalendarEventInfo(id: "a", title: "Client", start: start, end: start.addingTimeInterval(3600), calendarID: "work"),
            CalendarEventInfo(id: "b", title: "Dentist", start: start, end: start.addingTimeInterval(3600), calendarID: "home"),
            CalendarEventInfo(id: "c", title: "Late", start: day(2026, 11, 10, 9), end: day(2026, 11, 10, 10), calendarID: "work")
        ]
        let got = w.events(from: day(2026, 11, 9), to: day(2026, 11, 10), calendarIDs: ["work"])
        #expect(got.map(\.id) == ["a"])
        #expect(w.delete(eventID: "a") == .deleted)
        #expect(w.deleted == ["a"])
    }
}
