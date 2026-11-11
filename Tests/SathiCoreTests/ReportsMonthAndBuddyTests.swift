import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Reports streak months and buddy tab")
struct ReportsMonthAndBuddyTests {
    private let november = StatsRange.containing(day(2026, 11, 11), kind: .month, calendar: .current)

    @Test func theOverviewMonthStartsOnMondayWithLeadingBlanks() {
        let month = ReportsOverviewTests.harness().engine.streakOverview(november)
        #expect(month.title == "November 2026")
        #expect(month.leadingBlanks == 6)
        #expect(month.days.count == 30)
        #expect(month.canGoForward == false)
    }

    @Test func eachDayHasFourDotsAndAStreakDayIsMarked() {
        let month = ReportsOverviewTests.harness().engine.streakOverview(november)
        let ninth = month.days[8]
        #expect(ninth.dots.map(\.habit) == HabitID.allCases)
        let allMet = ninth.dots.allSatisfy(\.isMet)
        #expect(allMet)
        #expect(ninth.isStreakDay)
        #expect(month.days[9].dots.map(\.isMet) == [true, false, true, false])
        #expect(month.days[9].isStreakDay == false)
        #expect(month.days[10].isToday)
        #expect(month.days[11].isFuture)
        #expect(month.streakText == "Streak 0 days")
    }

    @Test func theMonthBeforeCanGoForward() {
        let month = ReportsOverviewTests.harness().engine.streakOverview(november.previous)
        #expect(month.title == "October 2026")
        #expect(month.leadingBlanks == 3)
        #expect(month.canGoForward)
    }

    @Test func theBuddyMonthShadesEachDayByItsGoal() {
        let month = ReportsOverviewTests.harness().engine.buddyMonth(november, habit: .reading)
        #expect(month.title == "Boi · November")
        #expect(month.goalDaysText == "1 goal day")
        #expect(month.cells[8].state == .met)
        #expect(month.cells[9].state == .some)
        #expect(month.cells[10].state == BuddyDayState.none)
        #expect(month.cells[10].isToday)
        #expect(month.cells[11].state == .future)
        #expect(month.leadingBlanks == 6)
    }

    @Test func theBuddyTabHasTitleGoalTotalAndFacts() {
        let tab = ReportsOverviewTests.harness().engine.buddyTab(ReportsOverviewTests.week(), habit: .gym)
        #expect(tab.title == "Shokti · gym minutes")
        #expect(tab.goalText == "daily goal 10 min")
        #expect(tab.totalLabel == "THIS WEEK")
        #expect(tab.totalText == "10m")
        #expect(tab.chart.bars.count == 7)
        #expect(tab.chart.goal == 10)
        #expect(tab.facts.map(\.label) == ["Goal days", "Best day", "Daily average", "Streak"])
        #expect(tab.facts.map(\.value) == ["1 of 7", "Mon · 10m", "3.3m", "0 days"])
    }

    @Test func theWaterTabCountsGlasses() {
        let tab = ReportsOverviewTests.harness().engine.buddyTab(ReportsOverviewTests.week(), habit: .water)
        #expect(tab.title == "Fota · glasses")
        #expect(tab.goalText == "daily goal 8 glasses")
        #expect(tab.totalText == "19 glasses")
        #expect(tab.facts.first?.value == "2 of 7")
        #expect(tab.changeText == "+11 glasses vs the same days last week")
        #expect(tab.isUp)
    }

    @Test func theAllBuddiesStreakCountsAcrossTheMonthStart() {
        let h = EngineHarness(at: day(2026, 11, 2, 20)) {
            $0.prefs.reading.enabled = false
            $0.events = [30, 31].map { .done(.water, 8, at: day(2026, 10, $0, 9)) }
                + [1, 2].map { .done(.water, 8, at: day(2026, 11, $0, 9)) }
        }
        #expect(h.engine.allBuddiesStreak() == 4)
    }
}
