import Foundation
import SathiCore
import Testing

@Suite("Copywriter today so far")
struct CopywriterTodaySoFarTests {
    @Test func changeUsesDayWords() {
        #expect(Copywriter.todaySoFarChange(.up(40 * 60)) == "+40m vs yesterday")
        #expect(Copywriter.todaySoFarChange(.up(3600)) == "+1h 0m vs yesterday")
        #expect(Copywriter.todaySoFarChange(.down(90 * 60)) == "\u{2212}1h 30m vs yesterday")
        #expect(Copywriter.todaySoFarChange(.same) == "same as yesterday")
    }

    @Test func noChangeIsEmpty() {
        #expect(Copywriter.todaySoFarChange(.none) == "")
    }

    @Test func breakdownCardTitleAndSummary() {
        #expect(Copywriter.dayBreakdownTitle == "Breakdown")
        #expect(Copywriter.dayBreakdownSummary(count: 2, total: 3 * 3600) == "2 categories · 3h 0m")
        #expect(Copywriter.dayBreakdownSummary(count: 1, total: 30 * 60) == "1 category · 30m")
    }
}
