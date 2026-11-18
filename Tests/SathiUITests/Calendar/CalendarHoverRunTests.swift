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
        try Fix.runner(h, spy).run(.startAsActivity, Fix.target(Fix.placed(h, "Standup")))
        #expect(h.engine.runningActivity?.text == "Standup")
        #expect(h.engine.runningActivity?.sourceEventID == "s")
    }

    @Test func openInCalendarOpensTheEventLink() throws {
        let h = Fix.harness()
        try Fix.runner(h, Fix.Spy()).run(.openInCalendar, Fix.target(Fix.placed(h, "Standup")))
        #expect(h.links.opened.last == URL(string: "ical://ekevent/s"))
    }

    @Test(arguments: ["Standup", "Write"])
    func editRunsTheSameJobAsAClick(_ title: String) throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        let placed = try Fix.placed(h, title)
        Fix.runner(h, spy).run(.edit, Fix.target(placed))
        #expect(spy.opened == [placed.block.id])
    }

    @Test func editAwayRunsTheSameJobAsAClick() {
        let h = Fix.harness()
        let spy = Fix.Spy()
        let away = Fix.away()
        Fix.runner(h, spy).run(.editAway, Fix.target(CalendarPlacedBlock(block: away, lane: 0, lanes: 1)))
        #expect(spy.opened == [away.id])
    }

    @Test func mergePicksTheActivityForMergeLikeACommandClick() throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        try Fix.runner(h, spy).run(.merge, Fix.target(Fix.placed(h, "Write")))
        #expect(spy.toggled == [Fix.write.id])
        #expect(spy.opened.isEmpty)
    }

    @Test func deleteRemovesTheActivity() throws {
        let h = Fix.harness()
        try Fix.runner(h, Fix.Spy()).run(.delete, Fix.target(Fix.placed(h, "Write")))
        #expect(!h.engine.calendarPage(Fix.range(h)).blocks.contains { $0.title == "Write" })
    }

    @Test func markDoneCompletesTheTodo() {
        let h = Fix.harness(todos: [makeTodo("a", "Call Rina")])
        Fix.runner(h, Fix.Spy()).run(.markDone, Fix.target(CalendarPlacedBlock(block: Fix.todo(), lane: 0, lanes: 1)))
        #expect(h.todos.calls == [.doneSet("a", true)])
    }

    @Test func editTodoOpensTheTodoEditor() {
        let h = Fix.harness()
        let spy = Fix.Spy()
        Fix.runner(h, spy).run(.edit, Fix.target(CalendarPlacedBlock(block: Fix.todo(), lane: 0, lanes: 1)))
        #expect(spy.todoEdits == ["t-a"])
        #expect(spy.opened.isEmpty)
    }

    @Test func openInRemindersOpensTheRemindersApp() {
        let h = Fix.harness()
        Fix.runner(h, Fix.Spy()).run(.openInReminders, Fix.target(CalendarPlacedBlock(block: Fix.todo(), lane: 0, lanes: 1)))
        #expect(h.links.opened.last == URL(fileURLWithPath: "/System/Applications/Reminders.app"))
    }

    @Test func startAsActivityIsHiddenForAPastEvent() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 12))
        let placed = try Fix.placed(h, "Standup")
        let shown = CalendarHoverRun.visible(h.engine.calendarHoverInfo(placed), canMerge: true)
        #expect(shown == [.edit, .openInCalendar])
    }

    @Test func startAsActivityShowsWhileTheEventIsNotOver() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 9, 29))
        let placed = try Fix.placed(h, "Standup")
        let shown = CalendarHoverRun.visible(h.engine.calendarHoverInfo(placed), canMerge: true)
        #expect(shown == [.startAsActivity, .edit, .openInCalendar])
    }

    @Test func mergeIsHiddenWhereTheViewCannotMerge() throws {
        let h = Fix.harness()
        let placed = try Fix.placed(h, "Write")
        let shown = CalendarHoverRun.visible(h.engine.calendarHoverInfo(placed), canMerge: false)
        #expect(shown == [.edit, .delete])
    }

    @Test func runningActivityHasNoActions() {
        let h = Fix.harness()
        let a = Activity(text: "Now", start: day(2026, 3, 4, 11), end: day(2026, 3, 4, 12))
        let block = CalendarBlock(
            id: "r", title: "Now", interval: a.interval, style: .activity(category: nil),
            source: .activity(a, running: true), isAllDay: false, activityIDs: []
        )
        let info = h.engine.calendarHoverInfo(CalendarPlacedBlock(block: block, lane: 0, lanes: 1))
        #expect(CalendarHoverRun.visible(info, canMerge: true).isEmpty)
    }

    @Test func failedDeleteShowsTheErrorLine() {
        let h = Fix.harness()
        let spy = Fix.Spy()
        let gone = Activity(text: "Gone", start: day(2026, 3, 4, 11), end: day(2026, 3, 4, 11, 30))
        let block = CalendarBlock(
            id: "g", title: "Gone", interval: gone.interval, style: .activity(category: nil),
            source: .activity(gone, running: false), isAllDay: false, activityIDs: [gone.id]
        )
        Fix.runner(h, spy).run(.delete, Fix.target(CalendarPlacedBlock(block: block, lane: 0, lanes: 1)))
        #expect(spy.failed == [Copywriter.activitiesDeleteFailed])
    }

    @Test func doneDeleteShowsNoErrorLine() throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        try Fix.runner(h, spy).run(.delete, Fix.target(Fix.placed(h, "Write")))
        #expect(spy.failed.isEmpty)
    }

    @Test func alsoHereRowRunsTheSameJobAsAClickOnThatBlock() throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        var first = try Fix.placed(h, "Standup")
        let hidden = try Fix.placed(h, "Write")
        first.hidden = [hidden]
        Fix.runner(h, spy).open(hidden: hidden.block.id, Fix.target(first))
        #expect(spy.opened == [hidden.block.id])
        #expect(spy.toggled.isEmpty)
    }

    @Test func commandClickOnAnAlsoHereRowPicksItForMerge() throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        spy.command = true
        var first = try Fix.placed(h, "Standup")
        let hidden = try Fix.placed(h, "Write")
        first.hidden = [hidden]
        Fix.runner(h, spy).open(hidden: hidden.block.id, Fix.target(first))
        #expect(spy.toggled == [Fix.write.id])
        #expect(spy.opened.isEmpty)
    }
}
