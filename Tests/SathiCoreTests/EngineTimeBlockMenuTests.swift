import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block menu")
struct EngineTimeBlockMenuTests {
    private func asking(_ answer: CalendarAccess) -> EngineHarness {
        let h = EngineHarness.quiet()
        h.calendarWriter.access = .notAsked
        h.calendarWriter.accessAfterRequest = answer
        h.engine.refreshCalendarAccess()
        return h
    }

    @Test func deniedFirstAskDoesNotOpenTheStartPopup() async {
        let h = asking(.denied)
        await h.engine.askThenOpenBlockStart()
        #expect(h.engine.calendarAccess == .denied)
        #expect(!h.presenter.calls.contains(.showBlockStart))
    }

    @Test func allowedFirstAskOpensTheStartPopup() async {
        let h = asking(.allowed)
        await h.engine.askThenOpenBlockStart()
        #expect(h.engine.calendarAccess == .allowed)
        #expect(h.presenter.calls.contains(.showBlockStart))
        #expect(!h.engine.calendarChoices().isEmpty)
    }

    @Test func calendarChoicesReadTheWriterOncePerRefresh() {
        let h = EngineHarness.quiet()
        h.engine.refreshCalendarAccess()
        let before = h.calendarWriter.calendarsCalls
        _ = h.engine.calendarChoices()
        _ = h.engine.calendarChoices()
        _ = h.engine.startCalendarID
        _ = h.engine.calendarTitle("work")
        #expect(h.calendarWriter.calendarsCalls == before)
        h.engine.refreshCalendarAccess()
        #expect(h.calendarWriter.calendarsCalls == before + 1)
    }

    @Test func refreshPicksUpANewCalendar() {
        let h = EngineHarness.quiet()
        _ = h.engine.calendarChoices()
        h.calendarWriter.choices.append(CalendarChoice(id: "team", title: "Team", account: "Gmail", colorHex: 0))
        h.engine.refreshCalendarAccess()
        #expect(h.engine.calendarChoices().map(\.id).contains("team"))
    }

    @Test func openingTheStartPopupRefreshesTheTime() {
        let h = EngineHarness.quiet()
        h.clock.advance(minutes: 7)
        h.engine.openBlockStart()
        #expect(h.engine.now == h.clock.now)
    }

    @Test func cancelClosesTheStartPopup() {
        let h = EngineHarness.quiet()
        h.engine.cancelBlockStart()
        #expect(h.presenter.calls.last == .closeBlockStart)
        #expect(h.engine.timeBlock == nil)
    }
}
