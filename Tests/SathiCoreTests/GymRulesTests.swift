import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("GymRules")
struct GymRulesTests {
    private let rules = GymRules(prefs: Prefs())

    private static let ny: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    private var workWeek: GymRules {
        var prefs = Prefs()
        prefs.gym.weekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        return GymRules(prefs: prefs)
    }

    private func rules(every interval: Int) -> GymRules {
        var prefs = Prefs()
        prefs.gym.intervalMinutes = interval
        return GymRules(prefs: prefs)
    }

    @Test func idAndGoal() {
        #expect(rules.id == .gym)
        #expect(rules.dailyGoal == 4)
    }

    @Test func beforeWorkStartsFirstReminderIsStartPlusInterval() {
        #expect(rules.nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: false) == day(2026, 3, 4, 10))
    }

    @Test func doneAtElevenIsDueAtTwelve() {
        #expect(rules.nextDue(now: day(2026, 3, 4, 11), lastDone: day(2026, 3, 4, 11), doneToday: 1, skipToday: false) == day(2026, 3, 4, 12))
    }

    @Test func goalMetDoesNotStopTheDay() {
        #expect(rules.nextDue(now: day(2026, 3, 4, 14), lastDone: day(2026, 3, 4, 14), doneToday: 4, skipToday: false) == day(2026, 3, 4, 15))
    }

    @Test func fridayEveningMovesToMondayFirstReminder() {
        let due = workWeek.nextDue(now: day(2026, 3, 6, 16, 30), lastDone: day(2026, 3, 6, 16, 30), doneToday: 3, skipToday: false)
        #expect(due == day(2026, 3, 9, 10))
    }

    @Test func lastDoneYesterdayGivesTodaysFirstReminder() {
        #expect(rules.nextDue(now: day(2026, 3, 5, 8), lastDone: day(2026, 3, 4, 16, 30), doneToday: 0, skipToday: false) == day(2026, 3, 5, 10))
    }

    @Test func lastReminderNeverAtOrAfterEnd() {
        let r = rules(every: 90)
        #expect(r.nextDue(now: day(2026, 3, 4, 16), lastDone: day(2026, 3, 4, 16), doneToday: 2, skipToday: false) == day(2026, 3, 5, 10, 30))
    }

    @Test func skipTodayMovesToNextWorkDay() {
        #expect(rules.nextDue(now: day(2026, 3, 4, 11), lastDone: nil, doneToday: 0, skipToday: true) == day(2026, 3, 5, 10))
    }

    @Test func activeOnlyInWorkHoursOnWorkDays() {
        #expect(workWeek.isActiveTime(day(2026, 3, 4, 9)))
        #expect(!workWeek.isActiveTime(day(2026, 3, 4, 17)))
        #expect(!workWeek.isActiveTime(day(2026, 3, 7, 11)))
    }

    @Test func nextActiveStartSkipsTheWeekend() {
        #expect(workWeek.nextActiveStart(after: day(2026, 3, 6, 18)) == day(2026, 3, 9, 9))
    }

    @Test func emptyWeekdaysCountAsEveryDay() {
        var prefs = Prefs()
        prefs.gym.weekdays = []
        let r = GymRules(prefs: prefs)
        #expect(r.nextDue(now: day(2026, 3, 7, 7), lastDone: nil, doneToday: 0, skipToday: false) == day(2026, 3, 7, 10))
    }

    @Test func startPlusIntervalAtOrAfterEndEveryDayHasNoReminder() {
        var prefs = Prefs()
        prefs.gym.startMinutes = 15 * 60
        prefs.gym.endMinutes = 16 * 60
        prefs.gym.intervalMinutes = 60
        let r = GymRules(prefs: prefs)
        #expect(r.nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: false) == .distantFuture)
        #expect(r.nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: true) == .distantFuture)
    }

    @Test func candidateAtTheEndSkipsToTheNextWorkDay() {
        #expect(rules.nextDue(now: day(2026, 3, 4, 16), lastDone: day(2026, 3, 4, 16), doneToday: 3, skipToday: false) == day(2026, 3, 5, 10))
    }

    @Test(arguments: [
        (day(2026, 3, 4, 11), day(2026, 3, 5, 8), day(2026, 3, 5, 10)),
        (day(2026, 3, 4, 11), day(2026, 3, 5, 10, 30), day(2026, 3, 5, 11, 30)),
        (day(2026, 3, 4, 11), day(2026, 3, 5, 17, 30), day(2026, 3, 6, 10)),
        (day(2026, 3, 6, 11), day(2026, 3, 9, 8), day(2026, 3, 9, 10))
    ])
    func staleLastDoneCountsFromNow(_ done: Date, _ now: Date, _ expected: Date) {
        #expect(rules.nextDue(now: now, lastDone: done, doneToday: 0, skipToday: false) == expected)
    }

    @Test(arguments: [(3, 8), (11, 1)])
    func dstMorningKeepsWallClockTime(_ month: Int, _ dayOfMonth: Int) throws {
        var prefs = Prefs()
        prefs.gym.weekdays = Set(Weekday.allCases)
        let r = GymRules(prefs: prefs, calendar: Self.ny)
        let now = try #require(Self.ny.date(from: DateComponents(year: 2026, month: month, day: dayOfMonth, hour: 7)))
        let due = r.nextDue(now: now, lastDone: nil, doneToday: 0, skipToday: false)
        let c = Self.ny.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        #expect([c.year, c.month, c.day, c.hour, c.minute] == [2026, month, dayOfMonth, 10, 0])
    }

    @Test func lastDoneIsTheLastDoneGymEvent() {
        var data = Persisted()
        #expect(data.lastDone(.gym) == nil)
        data.events = [
            .done(.gym, 1, at: day(2026, 3, 4, 10)),
            .done(.gym, 1, at: day(2026, 3, 4, 11)),
            .snooze(.gym, at: day(2026, 3, 4, 14)),
            .done(.meditation, 5, at: day(2026, 3, 4, 15))
        ]
        #expect(data.lastDone(.gym) == day(2026, 3, 4, 11))
    }

    @Test func totalCountsThatDaysWorkouts() {
        var data = Persisted()
        data.events = [
            .done(.gym, 1, at: day(2026, 3, 3, 16)),
            .done(.gym, 1, at: day(2026, 3, 4, 10)),
            .done(.gym, 1, at: day(2026, 3, 4, 11)),
            .skip(.gym, at: day(2026, 3, 4, 12))
        ]
        #expect(rules.total(on: day(2026, 3, 4, 12), data: data) == 2)
    }
}
