import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Calendar week narrow face")
struct CalendarWeekNarrowFaceTests {
    @Test func planHalfAtSevenDaysShowsTimeAndTitleOnOneLine() {
        #expect(CalendarWeekNarrowFace.pick(width: 79, height: 22) == .inline)
    }

    @Test func aTallBlockPutsTheTitleUnderTheTime() {
        #expect(CalendarWeekNarrowFace.pick(width: 79, height: 34) == .stacked)
        #expect(CalendarWeekNarrowFace.pick(width: 118, height: 120) == .stacked)
    }

    @Test func aRaisedEventInThePlanHalfStillShowsItsTime() {
        let raised = 79 - UIMetrics.calendarCascadeIndent
        #expect(CalendarWeekNarrowFace.pick(width: raised, height: 22) == .inline)
    }

    @Test func aHalfTooNarrowForTheTimeShowsTheTitleOnly() {
        #expect(CalendarWeekNarrowFace.pick(width: 37, height: 22) == .titleOnly)
        #expect(CalendarWeekNarrowFace.pick(width: 37, height: 60) == .titleOnly)
    }

    @Test func aJoinedActivityUsesItsCategoryColorForTheEdge() {
        let cats = [ActivityCategory(name: "Focus", colorHex: 0x3366CC)]
        let edge = CalendarWeekBlock.edge(.joined(category: "Focus"), categories: cats)
        #expect(edge == Color(hex: ActivityColors.hex("Focus", in: cats)))
        #expect(edge == CalendarWeekBlock.edge(.activity(category: "Focus"), categories: cats))
        #expect(edge != Night.text)
    }
}
