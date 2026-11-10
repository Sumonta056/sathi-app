import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker calendar row")
struct TrackerCalendarRowTests {
    private final class Box {
        var draft = ActivityDraft(text: "Write spec")
    }

    private let calendars = [
        CalendarChoice(id: "work", title: "Work", account: "iCloud", colorHex: 0x4CC3F5),
        CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853)
    ]

    private func row(_ box: Box, defaultID: String?) -> TrackerCalendarRow {
        let binding = Binding(get: { box.draft }, set: { box.draft = $0 })
        return TrackerCalendarRow(draft: binding, calendars: calendars, defaultID: defaultID)
    }

    @Test func tickingPicksTheDefaultCalendar() throws {
        let box = Box()
        try Prompt.tap(row(box, defaultID: "home").inspect(), "tracker.calendar.check")
        #expect(box.draft.calendarID == "home")
    }

    @Test func tickingWithNoDefaultPicksTheFirstCalendar() throws {
        let box = Box()
        try Prompt.tap(row(box, defaultID: nil).inspect(), "tracker.calendar.check")
        #expect(box.draft.calendarID == "work")
    }

    @Test func tickingAgainTurnsItOff() throws {
        let box = Box()
        box.draft.calendarID = "home"
        try Prompt.tap(row(box, defaultID: "home").inspect(), "tracker.calendar.check")
        #expect(box.draft.calendarID == nil)
    }

    @Test func theMenuShowsTheDefaultWhileOff() throws {
        let sut = try row(Box(), defaultID: "home").inspect()
        #expect(throws: Never.self) { try sut.find(text: "Home") }
    }

    @Test func thePromptsPassTheDefaultFromTheState() throws {
        let s = Prompt.state(.whatNow) {
            $0.calendars = calendars
            $0.defaultCalendarID = "home"
        }
        let sut = try WhatNowPopup(state: s).inspect()
        #expect(try sut.find(TrackerCalendarRow.self).actualView().defaultID == "home")
        let center = try CenterPromptView(state: Prompt.state(.center) { $0.defaultCalendarID = "home" }).inspect()
        #expect(try center.find(TrackerCalendarRow.self).actualView().defaultID == "home")
    }
}
