import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar hover card actions")
struct CalendarHoverRunTests {
    typealias Fix = CalendarHoverFixtures

    @Test func startAsActivityStartsTheEventAsTheRunningActivity() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 9, 10))
        let spy = Fix.Spy()
        try Fix.runner(h, spy).run(.startAsActivity, Fix.target(Fix.laid(h, "Standup")))
        #expect(h.engine.runningActivity?.text == "Standup")
        #expect(h.engine.runningActivity?.sourceEventID == "s")
    }

    @Test func openInCalendarOpensTheEventLink() throws {
        let h = Fix.harness()
        try Fix.runner(h, Fix.Spy()).run(.openInCalendar, Fix.target(Fix.laid(h, "Standup")))
        #expect(h.links.opened.last == URL(string: "ical://ekevent/s"))
    }

    @Test(arguments: ["Standup", "Write"])
    func editRunsTheSameJobAsAClick(_ title: String) throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        let placed = try Fix.laid(h, title)
        Fix.runner(h, spy).run(.edit, Fix.target(placed))
        #expect(spy.opened == [placed.id])
    }

    @Test func editAwayRunsTheSameJobAsAClick() {
        let h = Fix.harness()
        let spy = Fix.Spy()
        let away = Fix.away()
        Fix.runner(h, spy).run(.editAway, Fix.target(Fix.laid(away)))
        #expect(spy.opened == [away.id])
    }

    @Test func deleteRemovesTheActivity() throws {
        let h = Fix.harness()
        try Fix.runner(h, Fix.Spy()).run(.delete, Fix.target(Fix.laid(h, "Write")))
        #expect(!h.engine.calendarPageBase(Fix.range(h)).blocks.contains { $0.title == "Write" })
    }

    @Test func markDoneCompletesTheTodo() {
        let h = Fix.harness(todos: [makeTodo("a", "Call Rina")])
        Fix.runner(h, Fix.Spy()).run(.markDone, Fix.target(Fix.laid(Fix.todo())))
        #expect(h.todos.calls == [.doneSet("a", true)])
    }

    @Test func editTodoOpensTheTodoEditor() {
        let h = Fix.harness()
        let spy = Fix.Spy()
        Fix.runner(h, spy).run(.edit, Fix.target(Fix.laid(Fix.todo())))
        #expect(spy.todoEdits == ["t-a"])
        #expect(spy.opened.isEmpty)
    }

    @Test func openInRemindersOpensTheRemindersApp() {
        let h = Fix.harness()
        Fix.runner(h, Fix.Spy()).run(.openInReminders, Fix.target(Fix.laid(Fix.todo())))
        #expect(h.links.opened.last == URL(fileURLWithPath: "/System/Applications/Reminders.app"))
    }

    @Test func startAsActivityIsHiddenForAPastEvent() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 12))
        let placed = try Fix.laid(h, "Standup")
        let shown = CalendarHoverRun.visible(h.engine.calendarHoverInfo(placed, among: [placed]))
        #expect(shown == [.edit, .openInCalendar])
    }

    @Test func startAsActivityShowsWhileTheEventIsNotOver() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 9, 29))
        let placed = try Fix.laid(h, "Standup")
        let shown = CalendarHoverRun.visible(h.engine.calendarHoverInfo(placed, among: [placed]))
        #expect(shown == [.startAsActivity, .edit, .openInCalendar])
    }

    @Test func activityShowsEditAndDeleteAndNoMerge() throws {
        let h = Fix.harness()
        let placed = try Fix.laid(h, "Write")
        let shown = CalendarHoverRun.visible(h.engine.calendarHoverInfo(placed, among: [placed]))
        #expect(shown == [.edit, .delete])
    }

    @Test func runningActivityHasNoActions() {
        let h = Fix.harness()
        let a = Activity(text: "Now", start: day(2026, 3, 4, 11), end: day(2026, 3, 4, 12))
        let block = CalendarBlock(
            id: "r", title: "Now", interval: a.interval, style: .activity(category: nil),
            source: .activity(a, running: true), isAllDay: false, activityIDs: []
        )
        let laid = Fix.laid(block)
        let info = h.engine.calendarHoverInfo(laid, among: [laid])
        #expect(CalendarHoverRun.visible(info).isEmpty)
    }

    @Test func failedDeleteShowsTheErrorLine() {
        let h = Fix.harness()
        let spy = Fix.Spy()
        let gone = Activity(text: "Gone", start: day(2026, 3, 4, 11), end: day(2026, 3, 4, 11, 30))
        let block = CalendarBlock(
            id: "g", title: "Gone", interval: gone.interval, style: .activity(category: nil),
            source: .activity(gone, running: false), isAllDay: false, activityIDs: [gone.id]
        )
        Fix.runner(h, spy).run(.delete, Fix.target(Fix.laid(block)))
        #expect(spy.failed == [Copywriter.activitiesDeleteFailed])
    }

    @Test func doneDeleteShowsNoErrorLine() throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        try Fix.runner(h, spy).run(.delete, Fix.target(Fix.laid(h, "Write")))
        #expect(spy.failed.isEmpty)
    }

    @Test func alsoHereRowRunsTheSameJobAsAClickOnThatBlock() throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        var first = try Fix.laid(h, "Standup")
        let hidden = try Fix.laid(h, "Write")
        first.hidden = [hidden]
        Fix.runner(h, spy).open(row: hidden.block.id, Fix.target(first))
        #expect(spy.opened == [hidden.id])
    }
}
