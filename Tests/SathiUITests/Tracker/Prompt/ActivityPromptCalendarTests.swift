import Foundation
@testable import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt calendar boxes")
struct ActivityPromptCalendarTests {
    private let two = [
        CalendarChoice(id: "work", title: "Work", account: "iCloud", colorHex: 0x4CC3F5),
        CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853)
    ]

    private func settle() async {
        for _ in 0 ..< 10 {
            await Task.yield()
        }
    }

    @Test func everyCalendarAndNoneIsABox() throws {
        let s = Prompt.state(.whatNow) { $0.calendars = two }
        let model = ActivityPromptModel(s)
        let sut = try Prompt.view(s, model: model)
        #expect(Prompt.has(sut, "prompt.calendar.work"))
        #expect(Prompt.has(sut, "prompt.calendar.home"))
        #expect(Prompt.has(sut, "prompt.calendar.none"))
        try Prompt.tap(sut, "prompt.calendar.home")
        #expect(model.draft.calendarID == "home")
        try Prompt.tap(Prompt.view(s, model: model), "prompt.calendar.none")
        #expect(model.draft.calendarID == nil)
    }

    @Test func thePickedCalendarIsOnAndTheNoteNamesIt() throws {
        let s = Prompt.state(.whatNow) {
            $0.calendars = two
            $0.draft.calendarID = "work"
        }
        let sut = try Prompt.view(s)
        #expect(try Prompt.boxIsOn(sut, "prompt.calendar.work"))
        #expect(try !Prompt.boxIsOn(sut, "prompt.calendar.none"))
        #expect(Prompt.hasText(sut, "One event goes to Work when the activity ends."))
    }

    @Test func noneSaysNoEvent() throws {
        let s = Prompt.state(.whatNow) { $0.calendars = two }
        let sut = try Prompt.view(s)
        #expect(try Prompt.boxIsOn(sut, "prompt.calendar.none"))
        #expect(Prompt.hasText(sut, "Sathi adds no event for this activity."))
    }

    @Test func notAskedShowsTheAllowBoxAndAGrantLoadsTheCalendarsButPicksNone() async throws {
        let s = Prompt.state(.whatNow) {
            $0.calendars = []
            $0.calendarAccess = .notAsked
            $0.actions.allowCalendar = { TrackerCalendarInfo(access: .allowed, calendars: two, defaultID: "home") }
        }
        let model = ActivityPromptModel(s)
        let sut = try Prompt.view(s, model: model)
        #expect(Prompt.hasText(sut, "Allow calendar access"))
        try Prompt.tap(sut, "prompt.calendar.allow")
        await settle()
        #expect(model.draft.calendarID == nil)
        #expect(model.calendars.calendars.map(\.id) == ["work", "home"])
        let after = try Prompt.view(s, model: model)
        #expect(Prompt.has(after, "prompt.calendar.work"))
        #expect(try Prompt.boxIsOn(after, "prompt.calendar.none"))
    }

    @Test func aDenialPicksNothing() async throws {
        let s = Prompt.state(.whatNow) {
            $0.calendarAccess = .notAsked
            $0.actions.allowCalendar = { TrackerCalendarInfo(access: .denied, calendars: [], defaultID: nil) }
        }
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "prompt.calendar.allow")
        await settle()
        #expect(model.draft.calendarID == nil)
    }

    @Test func deniedShowsOpenSystemSettings() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) { $0.calendarAccess = .denied }
        let sut = try Prompt.view(s)
        #expect(!Prompt.has(sut, "prompt.calendar.none"))
        #expect(Prompt.hasText(sut, "Open System Settings"))
        try Prompt.tap(sut, "tracker.calendar.openSettings")
        #expect(calls.calls == ["openCalendarSettings"])
    }

    @Test func allowedWithNoCalendarsSaysSo() throws {
        let s = Prompt.state(.whatNow) { $0.calendars = [] }
        let sut = try Prompt.view(s)
        #expect(Prompt.has(sut, "tracker.calendar.none"))
        #expect(Prompt.hasText(sut, "No calendars found on this Mac."))
        #expect(!Prompt.has(sut, "prompt.calendar.none"))
    }

    @Test func theEventRowIsReadOnlyAndSaysAlreadyInYourCalendar() throws {
        let s = Reasons.withKeep(.eventAsk)
        let sut = try Prompt.view(s)
        #expect(Prompt.hasText(sut, "Already in your Work calendar, so Sathi adds no copy."))
        let box = try sut.find(viewWithAccessibilityIdentifier: "prompt.calendar.work").find(ViewType.Button.self, relation: .parent)
        #expect(box.isDisabled())
    }
}
