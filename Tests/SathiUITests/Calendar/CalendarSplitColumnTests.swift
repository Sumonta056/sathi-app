import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar split column")
struct CalendarSplitColumnTests {
    typealias Fix = CalendarSplitViewFixtures

    private let work = Fix.laid(Fix.activity("Write", Fix.at(10), Fix.at(11)), top: 240, bottom: 300)
    private let scrum = Fix.laid(Fix.event("Scrum", Fix.at(10), Fix.at(10, 30)), top: 240, bottom: 286)
    private let away = Fix.laid(Fix.activity("Away", Fix.at(13), Fix.at(14), kind: .away), top: 420, bottom: 480)

    private func column(
        _ kind: ReportRange, _ blocks: [CalendarLaidBlock], spy: Fix.Spy = Fix.Spy(), names: [String: String] = [:]
    ) -> CalendarSplitColumn {
        CalendarSplitColumn(
            day: Fix.monday, kind: kind, blocks: blocks, grid: Fix.grid([Fix.monday: blocks]), width: 526, now: nil,
            calendar: Fix.cal, categories: [], calendarNames: names, actions: Fix.actions(spy)
        )
    }

    private func tap(_ sut: InspectableView<ViewType.View<CalendarSplitColumn>>, _ laid: CalendarLaidBlock) throws {
        try sut.find(viewWithAccessibilityIdentifier: "calendar.split.block." + laid.id).callOnTapGesture()
    }

    @Test func aClickOnADayActivityCardOpensIt() throws {
        let spy = Fix.Spy()
        try tap(column(.day, [work, scrum, away], spy: spy).inspect(), work)
        #expect(spy.opened == [work.id])
    }

    @Test func aClickOnADayEventCardOpensIt() throws {
        let spy = Fix.Spy()
        try tap(column(.day, [work, scrum, away], spy: spy).inspect(), scrum)
        #expect(spy.opened == [scrum.id])
    }

    @Test func aClickOnADayAwayCardOpensIt() throws {
        let spy = Fix.Spy()
        try tap(column(.day, [work, scrum, away], spy: spy).inspect(), away)
        #expect(spy.opened == [away.id])
    }

    @Test func thePencilDoesWhatAClickDoes() throws {
        let spy = Fix.Spy()
        let card = try column(.day, [work], spy: spy).inspect().find(CalendarDayCard.self).actualView()
        card.edit()
        #expect(spy.opened == [work.id])
    }

    @Test func aWeekBlockClickOpensItToo() throws {
        let spy = Fix.Spy()
        try tap(column(.week, [work, scrum], spy: spy).inspect(), scrum)
        #expect(spy.opened == [scrum.id])
    }

    @Test func aDayEventCardGetsItsCalendarName() throws {
        let card = try column(.day, [scrum], names: ["work": "Work"]).inspect().find(CalendarDayCard.self).actualView()
        #expect(card.calendarName == "Work")
    }

    @Test func aDayActivityCardHasNoCalendarName() throws {
        let card = try column(.day, [work], names: ["work": "Work"]).inspect().find(CalendarDayCard.self).actualView()
        #expect(card.calendarName == nil)
    }

    @Test func aDayCardGetsTheLaidSize() throws {
        let card = try column(.day, [scrum]).inspect().find(CalendarDayCard.self).actualView()
        let halves = CalendarSplitGeometry.halves(column: 526, kind: .day)
        #expect(card.size == CalendarSplitGeometry.rect(scrum, halves: halves).size)
    }

    @Test func aTodoIsAPillOnItsDueLineAndNotACard() throws {
        var todo = Fix.laid(Fix.todo("Call Rina", Fix.at(15)), top: 540, bottom: 540)
        todo.half = .plan
        let sut = try column(.day, [work, todo]).inspect()
        #expect(sut.findAll(CalendarTodoChip.self).count == 1)
        #expect(sut.findAll(CalendarTodoDueLine.self).count == 1)
        #expect(sut.findAll(CalendarDayCard.self).count == 1)
    }

    @Test func theTodoDueLineSpansOnlyThePlanHalf() {
        let halves = CalendarSplitGeometry.halves(column: 526, kind: .day)
        let line = CalendarSplitGeometry.dueLine(top: 540, halves: halves)
        #expect(line.minX == halves.planX)
        #expect(line.width == halves.planWidth)
    }
}
