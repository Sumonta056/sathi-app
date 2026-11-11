import Foundation
import SathiCore
@testable import SathiUI
import Testing

@Suite("Activity report helpers")
struct ActivitySupportingTests {
    typealias Fix = ActivityViewSupport

    @Test func logRowsAddAGapRowBetweenActivities() {
        let rows = ActivityLogRows.make(Fix.day())
        #expect(rows.count == 4)
        if case let .gap(interval) = rows[1] {
            #expect(interval == DateInterval(start: Fix.at(4, 10, 30), end: Fix.at(4, 11)))
        } else {
            Issue.record("expected a gap")
        }
    }

    @Test func logRowsMarkTheRunningActivity() {
        let running = Fix.item("Now", nil, 4, (16, 0), (17, 0))
        let day = ActivityDay(day: Fix.key(4), hours: Fix.day().hours, activities: [], running: running)
        #expect(ActivityLogRows.make(day).contains(.activity(running, running: true)))
    }

    @Test func draftRoundTripsThroughMinutes() {
        let a = Fix.item("Plan", "Coding", 4, (9, 5), (10, 45))
        let draft = ActivityEditDraft(a, calendar: Fix.calendar)
        #expect(draft.startMinutes == 545)
        let edit = draft.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar)
        #expect(edit.start == a.start)
        #expect(edit.end == a.end)
    }

    @Test(arguments: [
        (ActivityEditResult.emptyText, "Type what you did."),
        (.tooShort, "An activity needs at least 1 min."),
        (.overlap, "This time overlaps another activity.")
    ])
    func editMessages(_ result: ActivityEditResult, _ text: String) {
        #expect(ActivityEditDraft.message(result) == text)
    }

    @Test func savedAndMissingShowNoMessage() {
        #expect(ActivityEditDraft.message(.saved(ActivityID())) == nil)
        #expect(ActivityEditDraft.message(.notFound) == nil)
    }

    @Test func axisMarksAreWholeHours() {
        let marks = ActivityAxis.marks(Fix.day().hours, calendar: Fix.calendar)
        #expect(marks.count == 10)
        #expect(marks.first == Fix.at(4, 9))
    }

    @Test func ribbonFractionsFollowHours() {
        let day = Fix.day()
        let seg = ActivityTimeline.segments(day)[0]
        let f = ActivityRibbon.fraction(seg, in: day.hours)
        #expect(f.start == 0)
        #expect(abs(f.width - 1.5 / 9) < 0.0001)
    }

    @Test func endOfDayAnimationNeverExceedsTheLimit() {
        for count in [1, 5, 40, 200] {
            #expect(EndOfDayAnimation.totalDuration(count: count) <= Timing.endOfDayAnimation)
        }
    }

    @Test func reduceMotionHasNoReveal() {
        #expect(EndOfDayAnimation.reveal(count: 5, revealed: true, reduceMotion: true) == nil)
        #expect(EndOfDayAnimation.reveal(count: 5, revealed: false, reduceMotion: false) != nil)
    }
}
