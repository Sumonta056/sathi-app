import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar hover host")
struct CalendarHoverHostTests {
    typealias Fix = CalendarHoverFixtures

    private final class Waits: @unchecked Sendable {
        var asked: [TimeInterval] = []
    }

    private func host(_ waits: Waits = Waits()) -> CalendarHoverHost {
        CalendarHoverHost { waits.asked.append($0) }
    }

    private var write: CalendarHoverTarget { Fix.target(CalendarPlacedBlock(block: Fix.away(), lane: 0, lanes: 1)) }

    private func other() -> CalendarHoverTarget {
        Fix.target(CalendarPlacedBlock(block: Fix.todo(), lane: 0, lanes: 1))
    }

    @Test func pointerOnABlockOpensTheCardAfterTheOpenDelay() async {
        let waits = Waits()
        let sut = host(waits)
        sut.block(write, inside: true)
        #expect(sut.shown == nil)
        await sut.settled()
        #expect(sut.shown?.id == write.id)
        #expect(waits.asked == [Timing.calendarHoverOpenDelay])
    }

    @Test func pointerLeavingClosesTheCardAfterTheCloseDelay() async {
        let waits = Waits()
        let sut = host(waits)
        sut.block(write, inside: true)
        await sut.settled()
        sut.block(write, inside: false)
        #expect(sut.shown?.id == write.id)
        await sut.settled()
        #expect(sut.shown == nil)
        #expect(waits.asked == [Timing.calendarHoverOpenDelay, Timing.calendarHoverCloseDelay])
    }

    @Test func leavingBeforeTheDelayNeverOpensTheCard() async {
        let sut = host()
        sut.block(write, inside: true)
        sut.block(write, inside: false)
        await sut.settled()
        #expect(sut.shown == nil)
    }

    @Test func movingFromTheBlockOntoTheCardKeepsItOpen() async {
        let sut = host()
        sut.block(write, inside: true)
        await sut.settled()
        sut.block(write, inside: false)
        sut.card(true)
        await sut.settled()
        #expect(sut.shown?.id == write.id)
        sut.card(false)
        await sut.settled()
        #expect(sut.shown == nil)
    }

    @Test func childInsideAHostOpensTheChildAndLeavingItGoesBackToTheHost() async {
        let sut = host()
        let child = other()
        sut.block(write, inside: true)
        sut.block(child, inside: true)
        await sut.settled()
        #expect(sut.shown?.id == child.id)
        sut.block(child, inside: false)
        await sut.settled()
        #expect(sut.shown?.id == write.id)
    }

    @Test func movingFromTheAwayPillOntoItsStripesKeepsTheCardOpen() async {
        let sut = host()
        var pill = write
        pill.part = .awayPill
        sut.block(pill, inside: true)
        await sut.settled()
        sut.block(write, inside: true)
        sut.block(pill, inside: false)
        await sut.settled()
        #expect(sut.shown?.id == write.id)
        sut.block(write, inside: false)
        await sut.settled()
        #expect(sut.shown == nil)
    }

    @Test func newDataKeepsTheCardWhileItsBlockIsStillThere() async {
        let sut = host()
        sut.block(write, inside: true)
        await sut.settled()
        sut.keep(ids: [write.id, other().id])
        #expect(sut.shown?.id == write.id)
    }

    @Test func newDataClosesTheCardWhenItsBlockIsGone() async {
        let sut = host()
        sut.block(write, inside: true)
        await sut.settled()
        sut.keep(ids: [other().id])
        #expect(sut.shown == nil)
    }

    @Test func closeHidesTheCardAtOnce() async {
        let sut = host()
        sut.block(write, inside: true)
        await sut.settled()
        sut.close()
        #expect(sut.shown == nil)
    }

    @Test func delaysMatchTheSpec() {
        #expect(Timing.calendarHoverOpenDelay == 0.35)
        #expect(Timing.calendarHoverCloseDelay == 0.2)
    }

    @Test(arguments: [(4, true), (5, true), (6, true), (7, false), (1, false), (2, false), (3, false)])
    func wednesdayToFridayPreferTheLeftSide(_ weekday: Int, _ left: Bool) {
        #expect(CalendarHoverPlacement.prefersLeft(weekday: weekday) == left)
    }

    @Test func cardOpensOnTheRightOfTheBlock() {
        let rect = CGRect(x: 100, y: 0, width: 80, height: 30)
        let x = CalendarHoverPlacement.x(block: rect, card: 200, width: 1000, prefersLeft: false)
        #expect(x == rect.maxX + UIMetrics.calendarHoverGap)
    }

    @Test func cardOpensOnTheLeftForWednesdayToFriday() {
        let rect = CGRect(x: 600, y: 0, width: 80, height: 30)
        let x = CalendarHoverPlacement.x(block: rect, card: 200, width: 1000, prefersLeft: true)
        #expect(x == rect.minX - UIMetrics.calendarHoverGap - 200)
    }

    @Test func cardFlipsToTheLeftWhenTheRightSideHasNoRoom() {
        let rect = CGRect(x: 700, y: 0, width: 200, height: 30)
        let x = CalendarHoverPlacement.x(block: rect, card: 200, width: 1000, prefersLeft: false)
        #expect(x == rect.minX - UIMetrics.calendarHoverGap - 200)
    }

    @Test func cardStaysInsideTheGridWhenNeitherSideHasRoom() {
        let rect = CGRect(x: 60, y: 0, width: 900, height: 30)
        let x = CalendarHoverPlacement.x(block: rect, card: 200, width: 1000, prefersLeft: false)
        #expect(x == 800)
    }
}
