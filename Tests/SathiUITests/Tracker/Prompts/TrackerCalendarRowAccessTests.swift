import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker calendar row access")
struct TrackerCalendarRowAccessTests {
    private final class Box {
        var draft = ActivityDraft(text: "Write spec")
        var allows = 0
        var opens = 0
    }

    private let calendars = [
        CalendarChoice(id: "work", title: "Work", account: "iCloud", colorHex: 0x4CC3F5),
        CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853)
    ]

    private func row(_ box: Box, _ access: CalendarAccess, calendars: [CalendarChoice] = []) -> TrackerCalendarRow {
        let binding = Binding(get: { box.draft }, set: { box.draft = $0 })
        return TrackerCalendarRow(
            draft: binding,
            calendars: calendars,
            defaultID: calendars.last?.id,
            access: access,
            onAllow: { box.allows += 1 },
            onOpenSettings: { box.opens += 1 }
        )
    }

    private func settle() async {
        for _ in 0 ..< 10 {
            await Task.yield()
        }
    }

    @Test func notAskedTickAsksForAccessAndLeavesTheDraftOff() throws {
        let box = Box()
        try Prompt.tap(row(box, .notAsked).inspect(), "tracker.calendar.check")
        #expect(box.allows == 1)
        #expect(box.opens == 0)
        #expect(box.draft.calendarID == nil)
    }

    @Test func notAskedShowsNoSettingsButtonAndNoNote() throws {
        let sut = try row(Box(), .notAsked).inspect()
        #expect(Prompt.has(sut, "tracker.calendar.check"))
        #expect(!Prompt.has(sut, "tracker.calendar.openSettings"))
        #expect(!Prompt.has(sut, "tracker.calendar.none"))
    }

    @Test func deniedShowsOpenSystemSettingsAndNoCheckBox() throws {
        let box = Box()
        let sut = try row(box, .denied).inspect()
        #expect(Prompt.has(sut, "tracker.calendar.openSettings"))
        #expect(Prompt.hasText(sut, Copywriter.blockOpenSettings))
        #expect(Copywriter.blockOpenSettings == "Open System Settings")
        #expect(!Prompt.has(sut, "tracker.calendar.check"))
        #expect(!Prompt.has(sut, "tracker.calendar.none"))
    }

    @Test func deniedTapOpensSystemSettings() throws {
        let box = Box()
        try Prompt.tap(row(box, .denied).inspect(), "tracker.calendar.openSettings")
        #expect(box.opens == 1)
        #expect(box.allows == 0)
        #expect(box.draft.calendarID == nil)
    }

    @Test func allowedWithNoCalendarsShowsTheNote() throws {
        let sut = try row(Box(), .allowed).inspect()
        #expect(Prompt.has(sut, "tracker.calendar.none"))
        #expect(Prompt.hasText(sut, Copywriter.trackerNoCalendars))
        #expect(Copywriter.trackerNoCalendars == "No calendars found on this Mac.")
        #expect(!Prompt.has(sut, "tracker.calendar.openSettings"))
    }

    @Test func allowedWithNoCalendarsIgnoresClicks() {
        let box = Box()
        try? Prompt.tap(row(box, .allowed).inspect(), "tracker.calendar.check")
        #expect(box.draft.calendarID == nil)
        #expect(box.allows == 0)
        #expect(box.opens == 0)
    }

    @Test func allowedWithCalendarsTicksTheDefaultAndNeverAsks() throws {
        let box = Box()
        let sut = try row(box, .allowed, calendars: calendars).inspect()
        #expect(!Prompt.has(sut, "tracker.calendar.openSettings"))
        #expect(!Prompt.has(sut, "tracker.calendar.none"))
        try Prompt.tap(sut, "tracker.calendar.check")
        #expect(box.draft.calendarID == "home")
        try Prompt.tap(row(box, .allowed, calendars: calendars).inspect(), "tracker.calendar.check")
        #expect(box.draft.calendarID == nil)
        #expect(box.allows == 0)
    }

    @Test(arguments: [PromptKind.whatNow, .center])
    func thePromptsPassTheAccessFromTheState(_ kind: PromptKind) throws {
        let s = Prompt.state(kind) {
            $0.calendars = []
            $0.calendarAccess = .denied
        }
        let sut = try Prompt.popup(kind, s)
        #expect(try sut.find(TrackerCalendarRow.self).actualView().access == .denied)
    }

    @Test(arguments: [PromptKind.whatNow, .center])
    func aNotAskedTickInAPromptCallsTheAllowAction(_ kind: PromptKind) async throws {
        let calls = PromptCalls()
        let s = Prompt.state(kind, calls: calls) {
            $0.calendars = []
            $0.calendarAccess = .notAsked
        }
        try Prompt.tap(Prompt.popup(kind, s), "tracker.calendar.check")
        await settle()
        #expect(calls.calls == ["allowCalendar"])
    }

    @Test(arguments: [PromptKind.whatNow, .center])
    func theSettingsButtonInAPromptCallsTheOpenSettingsAction(_ kind: PromptKind) throws {
        let calls = PromptCalls()
        let s = Prompt.state(kind, calls: calls) {
            $0.calendars = []
            $0.calendarAccess = .denied
        }
        try Prompt.tap(Prompt.popup(kind, s), "tracker.calendar.openSettings")
        #expect(calls.calls == ["openCalendarSettings"])
    }
}
