@testable import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker calendar grant")
struct TrackerCalendarGrantTests {
    private let calendars = [
        CalendarChoice(id: "work", title: "Work", account: "iCloud", colorHex: 0),
        CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0)
    ]

    private func settle() async {
        for _ in 0 ..< 10 {
            await Task.yield()
        }
    }

    private func tick(_ kind: PromptKind, answer: TrackerCalendarInfo) async throws -> TrackerDraftForm {
        let s = Prompt.state(kind) {
            $0.calendars = []
            $0.calendarAccess = .notAsked
            $0.actions.allowCalendar = { answer }
        }
        let form = TrackerDraftForm(s.draft)
        try Prompt.tap(Prompt.popup(kind, s, form: form), "tracker.calendar.check")
        await settle()
        return form
    }

    @Test(arguments: [PromptKind.whatNow, .center])
    func aGrantTicksTheDefaultCalendar(_ kind: PromptKind) async throws {
        let form = try await tick(kind, answer: TrackerCalendarInfo(access: .allowed, calendars: calendars, defaultID: "home"))
        #expect(form.draft.calendarID == "home")
    }

    @Test(arguments: [PromptKind.whatNow, .center])
    func aDenialTicksNothing(_ kind: PromptKind) async throws {
        let form = try await tick(kind, answer: TrackerCalendarInfo(access: .denied, calendars: [], defaultID: nil))
        #expect(form.draft.calendarID == nil)
    }

    @Test(arguments: [(CalendarAccess.allowed, false), (.notAsked, true), (.denied, true)])
    func onlyAllowedWithNoCalendarsBlocksClicks(_ access: CalendarAccess, _ active: Bool) throws {
        let row = TrackerCalendarRow(
            draft: .constant(ActivityDraft(text: "", category: "", length: .open, calendarID: nil, quiet: false)),
            calendars: [], defaultID: nil, access: access, onAllow: {}, onOpenSettings: {}
        )
        #expect(try row.inspect().find(ViewType.HStack.self).allowsHitTesting() == active)
    }
}
