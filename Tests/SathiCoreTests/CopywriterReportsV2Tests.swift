import Foundation
@testable import SathiCore
import Testing

@Suite("Copywriter reports v2")
struct CopywriterReportsV2Tests {
    private func score(_ habit: HabitID, _ met: Int, _ counted: Int) -> BuddyScore {
        BuddyScore(habit: habit, met: met, days: 7, counted: counted, isOff: false)
    }

    @Test func theTabSaysNameAndGoalDays() {
        #expect(Copywriter.reportsTab(.water, met: 4, days: 7) == "Fota · 4/7")
    }

    @Test func theHeadlineNamesBestAndWeakest() {
        let scores = [score(.water, 4, 4), score(.reading, 3, 4), score(.gym, 1, 4)]
        #expect(Copywriter.reportsHeadline(.week, scores: scores) == "Good week. Fota leads, Shokti needs a push.")
    }

    @Test func everyGoalMetIsAGreatWeek() {
        let scores = [score(.water, 3, 3), score(.reading, 3, 3)]
        #expect(Copywriter.reportsHeadline(.week, scores: scores) == "Great week. Every goal met.")
    }

    @Test func aSlowDayWithNothingMet() {
        #expect(Copywriter.reportsHeadline(.day, scores: [score(.water, 0, 1)]) == "Slow day. Every goal is still open.")
    }

    @Test func evenBuddiesAreEven() {
        let scores = [score(.water, 1, 2), score(.reading, 1, 2)]
        #expect(Copywriter.reportsHeadline(.month, scores: scores) == "Good month. Every buddy is even.")
    }

    @Test func noCountedDaysIsQuiet() {
        #expect(Copywriter.reportsHeadline(.week, scores: [score(.water, 0, 0)]) == "A quiet week so far.")
        #expect(Copywriter.reportsHeadline(.week, scores: []) == "A quiet week so far.")
    }

    @Test func theChangeLineHasSignAndStreak() {
        #expect(Copywriter.reportsScoreChange(3, kind: .week, isCurrent: true, streak: 1)
            == "+3 goals vs the same days last week · streak 1 day")
        #expect(Copywriter.reportsScoreChange(-1, kind: .month, isCurrent: false, streak: 4)
            == "\u{2212}1 goal vs last month · streak 4 days")
        #expect(Copywriter.reportsScoreChange(0, kind: .day, isCurrent: true, streak: 0)
            == "No change vs the same time yesterday · streak 0 days")
    }

    @Test func theScoreLabel() {
        #expect(Copywriter.reportsScoreLabel(.week, daysSoFar: 4, isCurrent: true) == "WEEK SCORE · 4 DAYS SO FAR")
        #expect(Copywriter.reportsScoreLabel(.month, daysSoFar: 1, isCurrent: true) == "MONTH SCORE · 1 DAY SO FAR")
        #expect(Copywriter.reportsScoreLabel(.day, daysSoFar: 1, isCurrent: true) == "DAY SCORE")
        #expect(Copywriter.reportsGoalsOf(28) == "of 28 goals")
    }

    @Test func shortAmounts() {
        #expect(Copywriter.reportsShortAmount(.water, 6) == "6")
        #expect(Copywriter.reportsShortAmount(.water, 6.5) == "6.5")
        #expect(Copywriter.reportsShortAmount(.reading, 30) == "30m")
        #expect(Copywriter.reportsShortAmount(.gym, 7.75) == "7.8m")
        #expect(Copywriter.reportsShortAmount(.reading, 90) == "1h 30m")
        #expect(Copywriter.reportsBarValue(.gym, 12, metGoal: true) == "12m \u{2713}")
    }

    @Test func theCategorySummaryShowsTheTotalChangeOrTheCount() {
        let changed = CategoryTable([
            CategoryTableInput(name: "Work", colorHex: 0, seconds: 7200, previousSeconds: 3600),
            CategoryTableInput(name: "Away", colorHex: 0, seconds: 600, previousSeconds: 1200)
        ])
        #expect(Copywriter.reportsCategorySummary(changed, kind: .week) == "+50m vs last week")
        let fresh = CategoryTable([CategoryTableInput(name: "Work", colorHex: 0, seconds: 7200)])
        #expect(Copywriter.reportsCategorySummary(fresh, kind: .week) == "logged · 1 category")
    }
}
