import Foundation
import SathiCore
import Testing

@Suite("Day summary verdict")
struct DaySummaryTests {
    private func summary(_ statuses: [DaySummaryStatus]) -> DaySummary {
        DaySummary(rows: zip(HabitID.allCases, statuses).map { DaySummaryRow(id: $0.0, status: $0.1, streak: 0) })
    }

    @Test(arguments: [(8.0, 8.0), (9.0, 8.0), (1.0, 1.0), (4.5, 4.0)])
    func progressAtOrAboveTheGoalIsMet(_ row: (Double, Double)) {
        #expect(DaySummaryStatus.progress(done: row.0, goal: row.1).isMet)
    }

    @Test(arguments: [(0.0, 8.0), (7.5, 8.0), (3.0, 4.0)])
    func progressBelowTheGoalIsNotMet(_ row: (Double, Double)) {
        #expect(!DaySummaryStatus.progress(done: row.0, goal: row.1).isMet)
    }

    @Test(arguments: [0.0, 3.0])
    func aZeroGoalIsNeverMet(_ done: Double) {
        #expect(!DaySummaryStatus.progress(done: done, goal: 0).isMet)
    }

    @Test func offAndDayOffAreNeverMet() {
        #expect(!DaySummaryStatus.off.isMet)
        #expect(!DaySummaryStatus.dayOff.isMet)
    }

    @Test func everyProgressRowMetIsAllMet() {
        let s = summary([.progress(done: 8, goal: 8), .progress(done: 15, goal: 15), .off, .dayOff])
        #expect(s.verdict == .allMet)
    }

    @Test func oneProgressRowMetIsAllMet() {
        let s = summary([.progress(done: 9, goal: 8), .off, .off, .off])
        #expect(s.verdict == .allMet)
    }

    @Test func someMetCountsOnlyProgressRows() {
        let s = summary([.progress(done: 8, goal: 8), .progress(done: 5, goal: 15), .dayOff, .progress(done: 1, goal: 4)])
        #expect(s.verdict == .someMet(met: 1, of: 3))
    }

    @Test func twoOfFourMetIsSomeMet() {
        let s = summary([.progress(done: 8, goal: 8), .progress(done: 0, goal: 15), .progress(done: 10, goal: 10), .progress(done: 2, goal: 4)])
        #expect(s.verdict == .someMet(met: 2, of: 4))
    }

    @Test func noProgressRowMetIsNoneMet() {
        let s = summary([.progress(done: 3, goal: 8), .progress(done: 0, goal: 15), .off, .dayOff])
        #expect(s.verdict == .noneMet)
    }

    @Test func aZeroGoalRowIsNotMetSoTheVerdictIsNoneMet() {
        let s = summary([.progress(done: 0, goal: 0), .off, .off, .off])
        #expect(s.verdict == .noneMet)
    }

    @Test func noProgressRowsIsARestDay() {
        #expect(summary([.dayOff, .off, .dayOff, .off]).verdict == .restDay)
    }

    @Test func allRowsOffIsARestDay() {
        #expect(summary([.off, .off, .off, .off]).verdict == .restDay)
    }

    @Test func noRowsIsARestDay() {
        #expect(DaySummary(rows: []).verdict == .restDay)
    }
}

@Suite("Day summary copy")
struct DaySummaryCopyTests {
    @Test func allMetCongratulates() {
        #expect(Copywriter.daySummaryTitle(.allMet, name: "Asha") == "Congratulations, Asha!")
        #expect(Copywriter.daySummaryHint(.allMet) == "Every goal met today.")
    }

    @Test func someMetSaysGoodDayAndCounts() {
        #expect(Copywriter.daySummaryTitle(.someMet(met: 2, of: 3), name: "Asha") == "Good day, Asha.")
        #expect(Copywriter.daySummaryHint(.someMet(met: 2, of: 3)) == "2 of 3 goals met.")
        #expect(Copywriter.daySummaryHint(.someMet(met: 1, of: 4)) == "1 of 4 goals met.")
    }

    @Test func noneMetSaysRestWell() {
        #expect(Copywriter.daySummaryTitle(.noneMet, name: "Asha") == "Rest well, Asha.")
        #expect(Copywriter.daySummaryHint(.noneMet) == "Tomorrow is a new day.")
    }

    @Test func restDaySaysEnjoyYourRest() {
        #expect(Copywriter.daySummaryTitle(.restDay, name: "Asha") == "Enjoy your rest, Asha.")
        #expect(Copywriter.daySummaryHint(.restDay) == "No goals today.")
    }

    @Test func theTitleUsesTheGivenName() {
        #expect(Copywriter.daySummaryTitle(.allMet, name: "Mridul") == "Congratulations, Mridul!")
        #expect(Copywriter.daySummaryTitle(.noneMet, name: "Rafi") == "Rest well, Rafi.")
    }
}
