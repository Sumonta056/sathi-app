import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar Day links")
struct CalendarDayLinksTests {
    private let halves = CalendarSplitGeometry.halves(column: 526, kind: .day)

    private var scrum: CalendarLaidBlock {
        DayFix.event("Personal Editorial scrum", DayFix.at(13, 0), DayFix.at(13, 25), top: 420, bottom: 466)
    }

    private var scurm: CalendarLaidBlock {
        var a = DayFix.activity("Personalized Editorial Scurm", DayFix.at(13, 0, 40), DayFix.at(13, 24, 10), top: 421, bottom: 467)
        a.doneDuring = scrum.id
        return a
    }

    private func expectMatchesCards(_ a: CalendarLaidBlock, _ e: CalendarLaidBlock) {
        let ra = CalendarSplitGeometry.rect(a, halves: halves)
        let re = CalendarSplitGeometry.rect(e, halves: halves)
        let mid = (halves.actualX + halves.actualWidth + halves.planX) / 2
        let points = CalendarDayLinks.points(activity: a, event: e, halves: halves)
        #expect(points == [
            CGPoint(x: ra.maxX, y: ra.midY), CGPoint(x: mid, y: ra.midY),
            CGPoint(x: mid, y: re.midY), CGPoint(x: re.minX, y: re.midY)
        ])
    }

    @Test func realWednesdayLinkRunsFromCardEdgeToCardEdge() {
        expectMatchesCards(scurm, scrum)
    }

    @Test func dotStaysInsideTheActivityCard() {
        var a = scurm
        a.top = 600
        a.bottom = 646
        let ra = CalendarSplitGeometry.rect(a, halves: halves)
        let first = CalendarDayLinks.points(activity: a, event: scrum, halves: halves).first
        #expect((first?.y ?? -1) >= ra.minY + UIMetrics.calendarDayLinkDot / 2)
        #expect((first?.y ?? .infinity) <= ra.maxY - UIMetrics.calendarDayLinkDot / 2)
    }

    @Test func linkStartsAtTheLaneCardRightEdge() {
        var a = scurm
        a.lanes = 2
        expectMatchesCards(a, scrum)
    }

    @Test func linkJoinsARaisedActivityToASecondLaneEvent() {
        var a = scurm
        a.depth = 1
        var e = scrum
        e.lanes = 2
        e.lane = 1
        expectMatchesCards(a, e)
        let points = CalendarDayLinks.points(activity: a, event: e, halves: halves)
        #expect(points.first?.x == CalendarSplitGeometry.rect(a, halves: halves).maxX)
        #expect(points.last?.x == CalendarSplitGeometry.rect(e, halves: halves).minX)
    }

    @Test func linkEndsAtARaisedEventLeftEdge() {
        var e = scrum
        e.depth = 1
        let points = CalendarDayLinks.points(activity: scurm, event: e, halves: halves)
        #expect(points.last?.x == halves.planX + UIMetrics.calendarCascadeIndent)
    }

    @Test func onlyDoneDuringActivitiesGetALinkInTheEventColor() {
        let other = DayFix.activity("Lunch", DayFix.at(14, 14), DayFix.at(14, 29), top: 500, bottom: 546)
        let links = CalendarDayLinks.links(
            blocks: [scurm, scrum, other], halves: halves, colors: [scrum.id: .red]
        )
        #expect(links.count == 1)
        #expect(links.first?.color == .red)
        #expect(links.first?.points.count == 4)
    }

    @Test func activityWhoseEventIsMissingHasNoLink() {
        let links = CalendarDayLinks.links(blocks: [scurm], halves: halves, colors: [:])
        #expect(links.isEmpty)
    }

    @Test func linksNeverTakeClicks() throws {
        let sut = CalendarDayLinks(blocks: [scurm, scrum], halves: halves, colors: [scrum.id: .red])
        #expect(try sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.day.links").allowsHitTesting() == false)
    }
}
