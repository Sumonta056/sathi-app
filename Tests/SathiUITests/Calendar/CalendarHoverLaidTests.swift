import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar hover on laid blocks")
struct CalendarHoverLaidTests {
    typealias Fix = CalendarSplitViewFixtures

    private func target(_ laid: CalendarLaidBlock, among: [CalendarLaidBlock]) -> CalendarHoverTarget {
        CalendarHoverTarget(
            day: Fix.monday, laid: laid, among: among, rect: CGRect(x: 10, y: 40, width: 80, height: 30), radius: 5, prefersLeft: false
        )
    }

    private func runner(_ spy: Fix.Spy) -> CalendarHoverRun {
        CalendarHoverRun(engine: EngineHarness(at: Fix.at(12)).engine, grid: Fix.actions(spy)) { _ in }
    }

    @Test func anAlsoHereRowDoesWhatAClickOnThatItemDoes() {
        let spy = Fix.Spy()
        let hidden = Fix.laid(Fix.activity("Hidden", Fix.at(10), Fix.at(11)), top: 0, bottom: 60)
        var shown = Fix.laid(Fix.activity("Shown", Fix.at(10), Fix.at(11)), top: 0, bottom: 60)
        shown.hidden = [hidden]
        runner(spy).open(row: hidden.id, target(shown, among: [shown]))
        #expect(spy.opened == [hidden.id])
    }

    @Test func aRowOfTheTargetItselfOpensIt() {
        let spy = Fix.Spy()
        let shown = Fix.laid(Fix.event("Scrum", Fix.at(10), Fix.at(11)), top: 0, bottom: 60)
        runner(spy).open(row: shown.id, target(shown, among: [shown]))
        #expect(spy.opened == [shown.id])
    }

    @Test func aRowOfAnotherBlockOfTheDayOpensIt() {
        let spy = Fix.Spy()
        let event = Fix.laid(Fix.event("Scrum", Fix.at(10), Fix.at(11)), top: 0, bottom: 60)
        let done = Fix.laid(Fix.activity("Notes", Fix.at(10), Fix.at(10, 40)), top: 0, bottom: 40)
        runner(spy).open(row: done.id, target(event, among: [event, done]))
        #expect(spy.opened == [done.id])
    }

    @Test func editRunsTheClickJob() {
        let spy = Fix.Spy()
        let shown = Fix.laid(Fix.activity("Write", Fix.at(10), Fix.at(11)), top: 0, bottom: 60)
        runner(spy).run(.edit, target(shown, among: [shown]))
        #expect(spy.opened == [shown.id])
    }

    @Test func theTargetIdIsTheBlockId() {
        let shown = Fix.laid(Fix.activity("Write", Fix.at(10), Fix.at(11)), top: 0, bottom: 60)
        #expect(target(shown, among: [shown]).id == shown.id)
    }
}
