import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar group block and narrow lanes")
struct CalendarGroupBlockTests {
    private let cal = Calendar.current
    private let cats = [ActivityCategory(name: "Work", colorHex: 0x7FB8FF), ActivityCategory(name: "Office", colorHex: 0xFFC94A)]

    private func act(_ id: String, _ from: Int, _ to: Int, title: String, category: String? = "Work") -> CalendarBlock {
        let s = day(2026, 11, 12, 10, from)
        let e = day(2026, 11, 12, 10, to)
        let a = Activity(text: title, category: category, start: s, end: e)
        return CalendarBlock(
            id: id, title: title, interval: DateInterval(start: s, end: e), style: .activity(category: category),
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
    }

    private var same: CalendarBlock {
        CalendarBlockGroup.block([act("a", 0, 5, title: "Testing"), act("b", 5, 9, title: "Testing"), act("c", 9, 14, title: "Testing")])
    }

    private var mixed: CalendarBlock {
        CalendarBlockGroup.block([
            act("a", 0, 5, title: "Mail", category: "Office"), act("b", 5, 12, title: "Code"), act("c", 12, 18, title: "Docs")
        ])
    }

    private func view(_ b: CalendarBlock, height: CGFloat, width: CGFloat) throws -> InspectableView<ViewType.ClassifiedView> {
        try CalendarActivityBlock(
            placed: CalendarPlacedBlock(block: b, lane: 0, lanes: 1), height: height,
            context: CalendarBlockContext(categories: cats), width: width
        ).inspect()
    }

    private func images(_ sut: InspectableView<ViewType.ClassifiedView>) -> [String] {
        sut.findAll(ViewType.Image.self).compactMap { try? $0.actualImage().name() }
    }

    @Test func aGroupHasTheStackIconAndItsBadge() throws {
        let sut = try view(same, height: 26, width: 200)
        #expect(images(sut).contains("square.stack"))
        #expect(throws: Never.self) { try sut.find(text: "×3") }
        #expect(throws: Never.self) { try sut.find(text: "Testing") }
    }

    @Test func aSingleBlockHasNoStackIcon() throws {
        #expect(try !images(view(act("a", 0, 40, title: "Code"), height: 40, width: 200)).contains("square.stack"))
    }

    @Test func mixedCategoriesShowADotEachInAWideLane() throws {
        let sut = try view(mixed, height: 60, width: 200)
        #expect(sut.findAll(where: { (try? $0.accessibilityIdentifier()) == "calendar.group.dot" }).count == 2)
    }

    @Test func dotsHideInANarrowLane() throws {
        let sut = try view(mixed, height: 60, width: 100)
        #expect(sut.findAll(where: { (try? $0.accessibilityIdentifier()) == "calendar.group.dot" }).isEmpty)
    }

    @Test func aCountTitleShowsTheTwoLongestTitlesWhenTall() throws {
        let sut = try view(mixed, height: 60, width: 200)
        #expect(throws: Never.self) { try sut.find(text: "3 activities") }
        #expect(throws: Never.self) { try sut.find(text: "Code · Docs") }
    }

    @Test func aTitleWrapsToTwoLinesInANarrowTallLane() throws {
        let long = act("a", 0, 50, title: "Bangladesh Bank Presentation Making")
        #expect(try view(long, height: 60, width: 100).find(text: long.title).lineLimit() == 2)
        #expect(try view(long, height: 60, width: 200).find(text: long.title).lineLimit() == 1)
        #expect(try view(long, height: 26, width: 100).find(text: long.title).lineLimit() == 1)
    }

    @Test func narrowShapesFollowTheColumnWidth() {
        let twoLanes = Set((0 ... Limits.calendarCascadeMaxDepth).map { CalendarLaneShape(depth: $0, lanes: 2) })
        #expect(CalendarNarrowLanes.shapes(columnWidth: 190) == twoLanes)
        #expect(CalendarNarrowLanes.shapes(columnWidth: 0) == [])
        #expect(CalendarNarrowLanes.shapes(columnWidth: 600) == [])
        #expect(CalendarNarrowLanes.shapes(columnWidth: 130).contains(CalendarLaneShape(depth: 0, lanes: 1)))
    }

    @Test func aCommandClickOnAGroupSelectsEveryMember() {
        var picked: [ActivityID] = []
        var grid = CalendarGridActions()
        grid.toggle = { _ in }
        grid.select = { picked += $0 }
        grid.command = { true }
        let group = same
        grid.press(DayKey(day(2026, 11, 12), calendar: cal), group, 0)
        #expect(picked == group.mergeIDs)
    }
}
