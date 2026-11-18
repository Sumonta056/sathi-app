import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar hover card info")
struct CalendarHoverInfoTests {
    private let cal = FixedZone.berlin.calendar
    private let lookup = CalendarHoverLookup(
        calendarNames: ["c": "Work"],
        readOnlyEventIDs: ["ro"],
        todoListNames: ["t1": "Groceries"]
    )

    private func info(_ placed: CalendarPlacedBlock) -> CalendarHoverInfo {
        CalendarHoverInfo.make(placed, lookup: lookup, calendar: cal)
    }

    private func placed(_ block: CalendarBlock) -> CalendarPlacedBlock {
        CalendarPlacedBlock(block: block, lane: 0, lanes: 1)
    }

    @Test func eventShowsPlanKindCalendarNameAndAllThreeActions() {
        let i = info(placed(Lay.event("e1", 0, 90)))
        #expect(i.kind == .event)
        #expect(i.kindLabel == "Calendar event · Plan")
        #expect(i.title == "e1")
        #expect(i.meta == "Work")
        #expect(i.actions == [.startAsActivity, .edit, .openInCalendar])
    }

    @Test func eventInTwoCalendarsSaysSoInTheMetaLine() {
        var b = Lay.event("e1", 0, 30)
        b.copies = 2
        #expect(info(placed(b)).meta == "Work · in 2 calendars")
    }

    @Test func readOnlyEventHasNoEdit() {
        let i = info(placed(Lay.event("ro", 0, 30)))
        #expect(i.kindLabel == "Calendar event · Plan")
        #expect(i.actions == [.startAsActivity, .openInCalendar])
    }

    @Test func activityShowsActualKindCategoryAndEditMergeDelete() {
        var b = Lay.activity("Spec", 0, 45)
        if case var .activity(a, running) = b.source {
            a.category = "Coding"
            b.source = .activity(a, running: running)
        }
        let i = info(placed(b))
        #expect(i.kind == .activity)
        #expect(i.kindLabel == "Activity · Actual")
        #expect(i.meta == "Coding")
        #expect(i.actions == [.edit, .merge, .delete])
    }

    @Test func activityWithNoCategorySaysNoCategory() {
        #expect(info(placed(Lay.activity("Spec", 0, 45))).meta == "No category")
    }

    @Test func todoShowsRemindersKindListNameAndTodoActions() {
        let b = CalendarBlock(
            id: "t-t1", title: "Buy milk", interval: DateInterval(start: Lay.at(30), end: Lay.at(30)),
            style: .todo(colorHex: 0), source: .todo("t1"), isAllDay: false, activityIDs: []
        )
        let i = info(placed(b))
        #expect(i.kind == .todo)
        #expect(i.kindLabel == "To-do · Apple Reminders")
        #expect(i.title == "Buy milk")
        #expect(i.meta == "Groceries")
        #expect(i.time == Copywriter.trackerClock(Lay.at(30), calendar: cal))
        #expect(i.length == nil)
        #expect(i.actions == [.markDone, .edit, .openInReminders])
    }

    @Test func awayShowsAwayKindReasonAndEditAway() {
        let a = Activity(kind: .away, text: "", start: Lay.at(0), end: Lay.at(60), awayPlace: .lunch)
        let b = CalendarBlock(
            id: "w", title: a.awayText, interval: a.interval, style: .away,
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
        let i = info(placed(b))
        #expect(i.kind == .away)
        #expect(i.kindLabel == "Away")
        #expect(i.meta == "Lunch")
        #expect(i.actions == [.editAway])
    }

    @Test func timeAndLengthComeFromTheRealSpanNotTheDisplaySpan() {
        var p = placed(Lay.event("e1", 0, 10))
        p.displaySpan = Lay.span(5, 40)
        let i = info(p)
        #expect(i.time == Copywriter.trackerSpan(Lay.at(0), Lay.at(10), calendar: cal))
        #expect(i.length == "10 min")
    }

    @Test func lengthShowsHoursAndMinutes() {
        #expect(info(placed(Lay.event("e1", 0, 90))).length == "1 h 30 min")
    }

    @Test func hostListsItsChildrenWithTheirRealTimes() {
        var host = placed(Lay.event("e1", 0, 60))
        var child = CalendarPlacedBlock(block: Lay.activity("Notes", 10, 40), lane: 0, lanes: 1, hostID: "e1")
        child.displaySpan = Lay.span(12, 50)
        host.children = [child]
        let i = info(host)
        #expect(i.childrenTitle == "Done in this event")
        #expect(i.children == [
            CalendarHoverChild(id: child.block.id, title: "Notes", time: Copywriter.trackerSpan(Lay.at(10), Lay.at(40), calendar: cal))
        ])
    }

    @Test func blockWithNoChildrenHasNoChildrenTitle() {
        let i = info(placed(Lay.event("e1", 0, 60)))
        #expect(i.children.isEmpty)
        #expect(i.childrenTitle == nil)
    }

    @Test func everyActionHasALabel() {
        let labels = CalendarHoverAction.allCases.map(Copywriter.calendarHoverAction)
        #expect(labels == [
            "Start as activity", "Edit", "Open in Calendar", "Merge", "Delete", "Mark done", "Open in Reminders", "Edit Away"
        ])
    }
}
