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
    private typealias F = DayFix
    private let actualWidth: CGFloat = 300
    private let planX: CGFloat = 326

    private var scrum: CalendarLaidBlock {
        F.event("Personal Editorial scrum", F.at(13, 0), F.at(13, 25), top: 420, bottom: 466)
    }

    private var scurm: CalendarLaidBlock {
        var a = F.activity("Personalized Editorial Scurm", F.at(13, 0, 40), F.at(13, 24, 10), top: 421, bottom: 467)
        a.doneDuring = scrum.id
        return a
    }

    @Test func realWednesdayLinkRunsAcrossDownAndAcross() {
        let points = CalendarDayLinks.points(activity: scurm, event: scrum, actualWidth: actualWidth, planX: planX)
        #expect(points == [
            CGPoint(x: 300, y: 444), CGPoint(x: 313, y: 444), CGPoint(x: 313, y: 443), CGPoint(x: 326, y: 443)
        ])
    }

    @Test func dotStaysInsideTheActivityCard() {
        var a = scurm
        a.top = 600
        a.bottom = 646
        let first = CalendarDayLinks.points(activity: a, event: scrum, actualWidth: actualWidth, planX: planX).first
        #expect((first?.y ?? -1) >= a.top + UIMetrics.calendarDayLinkDot / 2)
        #expect((first?.y ?? .infinity) <= a.bottom - UIMetrics.calendarDayLinkDot / 2)
    }

    @Test func linkStartsAtTheLaneCardRightEdge() {
        var a = scurm
        a.lanes = 2
        let points = CalendarDayLinks.points(activity: a, event: scrum, actualWidth: actualWidth, planX: planX)
        #expect(points.first?.x == 150)
    }

    @Test func linkEndsAtARaisedEventLeftEdge() {
        var e = scrum
        e.depth = 1
        let points = CalendarDayLinks.points(activity: scurm, event: e, actualWidth: actualWidth, planX: planX)
        #expect(points.last?.x == planX + UIMetrics.calendarCascadeIndent)
    }

    @Test func onlyDoneDuringActivitiesGetALinkInTheEventColor() {
        let other = F.activity("Lunch", F.at(14, 14), F.at(14, 29), top: 500, bottom: 546)
        let links = CalendarDayLinks.links(
            blocks: [scurm, scrum, other], actualWidth: actualWidth, planX: planX, colors: [scrum.id: .red]
        )
        #expect(links.count == 1)
        #expect(links.first?.color == .red)
        #expect(links.first?.points.count == 4)
    }

    @Test func activityWhoseEventIsMissingHasNoLink() {
        let links = CalendarDayLinks.links(blocks: [scurm], actualWidth: actualWidth, planX: planX, colors: [:])
        #expect(links.isEmpty)
    }

    @Test func linksNeverTakeClicks() throws {
        let sut = CalendarDayLinks(blocks: [scurm, scrum], actualWidth: actualWidth, planX: planX, colors: [scrum.id: .red])
        #expect(try sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.day.links").allowsHitTesting() == false)
    }
}
