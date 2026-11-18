import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar week block")
struct CalendarWeekBlockTests {
    typealias Fix = CalendarSplitViewFixtures

    private func block(_ laid: CalendarLaidBlock, narrow: Bool = false) -> CalendarWeekBlock {
        CalendarWeekBlock(laid: laid, size: CGSize(width: 160, height: laid.bottom - laid.top), narrow: narrow, calendar: Fix.cal, categories: [])
    }

    private func rounded(_ title: String) -> CalendarLaidBlock {
        var laid = Fix.laid(Fix.activity(title, Fix.at(14, 35), Fix.at(15, 2)), top: 0, bottom: 60)
        laid.rounded = DateInterval(start: Fix.at(14, 36), end: Fix.at(15, 2))
        return laid
    }

    @Test func showsTheTitleAndTheRoundedTimeWithLength() throws {
        let sut = try block(rounded("Code review")).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Code review") }
        #expect(throws: Never.self) { try sut.find(text: "2:36 – 3:02 PM · 26m") }
    }

    @Test func eventShowsTheCalendarIconTitleAndTime() throws {
        var laid = Fix.laid(Fix.event("Scrum", Fix.at(10, 30), Fix.at(11)), top: 0, bottom: 40)
        laid.rounded = laid.block.interval
        let sut = try block(laid).inspect()
        #expect(throws: Never.self) { try sut.find(ViewType.Image.self, where: { try $0.actualImage().name() == "calendar" }) }
        #expect(throws: Never.self) { try sut.find(text: "10:30 – 11:00 AM · 30m") }
    }

    @Test func narrowShowsTheStartTimeAndTitleWithoutTheRange() throws {
        let sut = try block(rounded("Code review"), narrow: true).inspect()
        #expect(throws: Never.self) { try sut.find(text: "2:36") }
        #expect(throws: Never.self) { try sut.find(text: "Code review") }
        #expect(Find.lacks(sut, text: "2:36 – 3:02 PM · 26m"))
    }

    @Test(arguments: [(22.0, 1), (33.9, 1), (34.0, 2), (80.0, 2)])
    func narrowWrapsToTwoLinesOnlyFromThirtyFourPoints(_ height: Double, _ lines: Int) {
        #expect(CalendarWeekBlock.titleLines(height: height, narrow: true) == lines)
    }

    @Test(arguments: [(34.0, 1), (49.0, 2), (64.0, 3), (200.0, 3)])
    func wideTitleGrowsToThreeLinesWhenTall(_ height: Double, _ lines: Int) {
        #expect(CalendarWeekBlock.titleLines(height: height, narrow: false) == lines)
    }

    @Test func awayIsADimStripedBlock() throws {
        let laid = Fix.laid(Fix.activity("Away", Fix.at(13), Fix.at(14), kind: .away), top: 0, bottom: 60)
        let sut = try block(laid).inspect()
        #expect(throws: Never.self) { try sut.find(CalendarStripes.self) }
    }

    @Test func doneDuringShowsADotInTheEventColor() throws {
        var laid = rounded("Standup notes")
        laid.doneDuring = "e1"
        let sut = try CalendarWeekBlock(
            laid: laid, size: CGSize(width: 160, height: 60), narrow: false, calendar: Fix.cal, categories: [],
            doneColor: .red
        ).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.week.doneDot") }
    }

    @Test func noDotWithoutDoneDuring() throws {
        let sut = try block(rounded("Solo")).inspect()
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "calendar.week.doneDot")) == nil)
    }

    @Test func hiddenItemsShowAPlusBadge() throws {
        var laid = rounded("Busy")
        laid.hidden = [rounded("Other")]
        let sut = try block(laid).inspect()
        #expect(throws: Never.self) { try sut.find(text: "+1") }
    }
}
