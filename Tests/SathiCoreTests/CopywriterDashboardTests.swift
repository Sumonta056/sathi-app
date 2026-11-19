import Foundation
@testable import SathiCore
import Testing

@Suite("Copywriter dashboard")
struct CopywriterDashboardTests {
    @Test func theScoreLineHasGoalsThenTheChange() {
        #expect(Copywriter.dashboardScoreLine(met: 2, possible: 4, change: "+1 vs yesterday") == "2 of 4 goals today · +1 vs yesterday")
    }

    @Test func theScoreLineWithSameAsYesterday() {
        #expect(Copywriter.dashboardScoreLine(met: 3, possible: 3, change: "same as yesterday") == "3 of 3 goals today · same as yesterday")
    }

    @Test func aHiddenChangeLeavesOnlyTheGoals() {
        #expect(Copywriter.dashboardScoreLine(met: 2, possible: 4, change: "") == "2 of 4 goals today")
    }

    @Test func noGoalMetStillShowsTheCount() {
        #expect(Copywriter.dashboardScoreLine(met: 0, possible: 1, change: "") == "0 of 1 goals today")
    }
}
