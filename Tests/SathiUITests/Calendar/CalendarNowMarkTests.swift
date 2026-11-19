import Foundation
@testable import SathiUI
import Testing

@Suite("Calendar now mark")
struct CalendarNowMarkTests {
    @Test(arguments: [(2.0, 6.5), (300.0, 300.0), (598.0, 593.5)])
    func thePillStaysInsideTheGrid(_ y: Double, _ expected: Double) {
        #expect(CalendarNowMark.pillY(CGFloat(y), gridHeight: 600) == CGFloat(expected))
    }

    @Test func aPillOverTheHourLabelHidesIt() {
        #expect(CalendarNowMark.hidesLabel(rowTop: 60, pillY: 70))
        #expect(CalendarNowMark.hidesLabel(rowTop: 60, pillY: 58))
    }

    @Test func aPillAwayFromTheHourLabelKeepsIt() {
        #expect(!CalendarNowMark.hidesLabel(rowTop: 60, pillY: 90))
        #expect(!CalendarNowMark.hidesLabel(rowTop: 60, pillY: 50))
    }
}
