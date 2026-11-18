import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar hover frames")
struct CalendarHoverFramesTests {
    typealias Fix = CalendarHoverFixtures

    private func frames(_ h: EngineHarness, _ blocks: [CalendarBlock], week: Bool = true, originX: CGFloat = 0) -> CalendarHoverFrames {
        let calendar = h.engine.rangeCalendar
        let key = DayKey(day(2026, 3, 4, 12), calendar: calendar)
        let math = CalendarGridMath(day: key, calendar: calendar, hourHeight: UIMetrics.calendarHourHeight)
        return CalendarHoverFrames(
            day: key, placed: math.place(blocks), math: math, width: 140, originX: originX,
            prefersLeft: week && CalendarHoverPlacement.prefersLeft(day: key, calendar: calendar)
        )
    }

    @Test func targetRectIsTheBlockRectInGridSpace() throws {
        let h = Fix.harness()
        let f = try frames(h, [Fix.block(h, "Write")], originX: 300)
        let p = try #require(f.placed.first)
        let t = f.target(p)
        #expect(t.rect == f.rect(p).offsetBy(dx: 300, dy: 0))
        #expect(t.radius == UIMetrics.calendarBlockRadius)
    }

    @Test func wednesdayInWeekPrefersTheLeftAndDayDoesNot() throws {
        let h = Fix.harness()
        let block = try Fix.block(h, "Write")
        let week = frames(h, [block])
        let dayView = frames(h, [block], week: false)
        #expect(try week.target(#require(week.placed.first)).prefersLeft)
        #expect(try !dayView.target(#require(dayView.placed.first)).prefersLeft)
    }

    @Test func childRectSitsInsideItsHost() throws {
        let h = Fix.harness()
        let event = try Fix.block(h, "Standup")
        let inside = Activity(text: "Notes", category: "Coding", start: day(2026, 3, 4, 9, 5), end: day(2026, 3, 4, 9, 25))
        let child = CalendarBlock(
            id: "c", title: "Notes", interval: inside.interval, style: .activity(category: "Coding"),
            source: .activity(inside, running: false), isAllDay: false, activityIDs: [inside.id]
        )
        let f = frames(h, [event, child])
        let host = try #require(f.placed.first { $0.block.id == event.id })
        let placedChild = try #require(host.children.first)
        let rect = f.target(placedChild).rect
        #expect(rect.minX == f.rect(host).minX + UIMetrics.calendarChildInset)
        #expect(rect.width == f.rect(host).width - 2 * UIMetrics.calendarChildInset)
        #expect(rect.minY == f.math.y(for: placedChild.displaySpan.start))
    }

    @Test func todoTargetIsThePill() {
        let h = Fix.harness()
        let f = frames(h, [Fix.todo()])
        let p = f.placed[0]
        #expect(f.target(p).rect == CalendarTodoLayer.pillRect(p, math: f.math, width: 140))
        #expect(f.target(p).radius == UIMetrics.calendarTodoPillHeight / 2)
    }

    @Test func stripeFindsTheAwayRowUnderThePointer() {
        let h = Fix.harness()
        let f = frames(h, [Fix.away()])
        let mid = f.math.y(for: day(2026, 3, 4, 13, 30))
        #expect(f.stripe(at: mid)?.block.id == Fix.away().id)
        #expect(f.stripe(at: f.math.y(for: day(2026, 3, 4, 15))) == nil)
    }
}
