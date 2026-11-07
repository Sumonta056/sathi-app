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

    private func rules(sessions: Int, minutes: Int) -> GymRules {
        var prefs = Prefs()
        prefs.gym.sessionsPerDay = sessions
        prefs.gym.sessionMinutes = minutes
        return GymRules(prefs: prefs)
    }

    private func due(_ r: GymRules? = nil, at now: Date, done: Double, last: Date? = nil, skip: Bool = false) -> Date {
        (r ?? rules).nextDue(now: now, lastDone: last, doneToday: done, skipToday: skip)
    }

    private func after(_ d: Date, hours: Double, over parts: Double) -> Date {
        d.addingTimeInterval(hours * Timing.hour / parts)
    }

    @Test func idAndGoalOfTwentyMinutes() {
        #expect(rules.id == .gym)
        #expect(rules.dailyGoal == 20)
    }

    @Test func goalFollowsSessionsTimesMinutes() {
        #expect(rules(sessions: 6, minutes: 10).dailyGoal == 60)
    }

    @Test(arguments: [day(2026, 3, 4, 7), day(2026, 3, 4, 8), day(2026, 3, 4, 9)])
    func beforeAnySessionTheFirstOfFourIsAtTen(_ now: Date) {
        #expect(due(at: now, done: 0) == day(2026, 3, 4, 10))
    }

    @Test func sessionsDoneOnTimeKeepTheEvenTimes() {
        #expect(due(at: day(2026, 3, 4, 10), done: 5, last: day(2026, 3, 4, 10)) == day(2026, 3, 4, 12))
        #expect(due(at: day(2026, 3, 4, 12), done: 10, last: day(2026, 3, 4, 12)) == day(2026, 3, 4, 14))
        #expect(due(at: day(2026, 3, 4, 14), done: 15, last: day(2026, 3, 4, 14)) == day(2026, 3, 4, 16))
    }

    @Test func aLateSessionReSpreadsTheRestFromTheDoneTime() {
        let d = day(2026, 3, 4, 10, 30)
        #expect(due(at: d, done: 5, last: d) == after(d, hours: 6.5, over: 3.5))
    }

    @Test func aMissedReminderStaysDueAndNeverSlides() {
        #expect(due(at: day(2026, 3, 4, 13), done: 0) == day(2026, 3, 4, 10))
        let d = day(2026, 3, 4, 10)
        #expect(due(at: day(2026, 3, 4, 15), done: 5, last: d) == day(2026, 3, 4, 12))
    }

    @Test func theDueTimeDoesNotDependOnNow() {
        let d = day(2026, 3, 4, 10, 30)
        #expect(due(at: day(2026, 3, 4, 10, 31), done: 5, last: d) == due(at: day(2026, 3, 4, 11, 45), done: 5, last: d))
    }

    @Test func sessionsLeftRoundUp() {
        let d = day(2026, 3, 4, 12)
        #expect(due(at: d, done: 6, last: d) == after(d, hours: 5, over: 3.5))
    }

    @Test func aPartLeftOfOneSessionStillCountsAsOneSession() {
        let d = day(2026, 3, 4, 12)
        #expect(due(rules(sessions: 4, minutes: 3), at: d, done: 10, last: d) == day(2026, 3, 4, 15, 20))
    }

    @Test func theNextReminderIsAtLeastOneSessionAfterADone() {
        let d = day(2026, 3, 4, 16, 54)
        #expect(due(at: d, done: 10, last: d) == day(2026, 3, 4, 16, 59))
    }

    @Test func aReminderThatWouldFallAfterWorkEndMovesToTomorrow() {
        let d = day(2026, 3, 4, 16, 57)
        #expect(due(at: d, done: 5, last: d) == day(2026, 3, 5, 10))
    }

    @Test func aDoneFromYesterdayIsIgnored() {
        #expect(due(at: day(2026, 3, 4, 9, 30), done: 0, last: day(2026, 3, 3, 15)) == day(2026, 3, 4, 10))
    }

    @Test func aDoneBeforeWorkStartSpreadsFromWorkStart() {
        #expect(due(at: day(2026, 3, 4, 8, 30), done: 5, last: day(2026, 3, 4, 8)) == day(2026, 3, 4, 10, 20))
    }

    @Test(arguments: [20.0, 25])
    func goalMetMovesToTheFirstReminderOfTomorrow(_ done: Double) {
        #expect(due(at: day(2026, 3, 4, 14), done: done) == day(2026, 3, 5, 10))
    }

    @Test func firstReminderOfADayFollowsTheSessionCount() {
        let r = rules(sessions: 2, minutes: 5)
        #expect(due(r, at: day(2026, 3, 4, 14), done: 10) == day(2026, 3, 5, 11))
        #expect(due(r, at: day(2026, 3, 4, 7), done: 0) == day(2026, 3, 4, 11))
    }

    @Test func beforeWorkStartTheSpreadStartsAtWorkStart() {
        #expect(due(rules(sessions: 6, minutes: 5), at: day(2026, 3, 4, 7), done: 0) == day(2026, 3, 4, 9, 40))
    }

    @Test func theLastSessionOfTheDayStillFitsBeforeWorkEnd() {
        let d = day(2026, 3, 4, 16)
        #expect(due(at: d, done: 15, last: d) == day(2026, 3, 4, 16, 40))
    }

    @Test(arguments: [day(2026, 3, 4, 17), day(2026, 3, 4, 20)])
    func atOrAfterWorkEndMovesToTheFirstReminderOfTomorrow(_ now: Date) {
        #expect(due(at: now, done: 5) == day(2026, 3, 5, 10))
    }

    @Test func skipTodayMovesToTheFirstReminderOfTomorrow() {
        #expect(due(at: day(2026, 3, 4, 11), done: 0, skip: true) == day(2026, 3, 5, 10))
    }

    @Test func fridayEveningMovesToMondayFirstReminder() {
        #expect(due(workWeek, at: day(2026, 3, 6, 17, 30), done: 15) == day(2026, 3, 9, 10))
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
        #expect(due(GymRules(prefs: prefs), at: day(2026, 3, 7, 7), done: 0) == day(2026, 3, 7, 10))
    }

    @Test(arguments: [(15 * 60, 15 * 60), (16 * 60, 15 * 60)])
    func endAtOrBeforeStartHasNoReminder(_ hours: (Int, Int)) {
        var prefs = Prefs()
        prefs.gym.startMinutes = hours.0
        prefs.gym.endMinutes = hours.1
        let r = GymRules(prefs: prefs)
        #expect(due(r, at: day(2026, 3, 4, 7), done: 0) == .distantFuture)
        #expect(due(r, at: day(2026, 3, 4, 7), done: 0, skip: true) == .distantFuture)
        #expect(due(r, at: day(2026, 3, 4, 15, 30), done: 20) == .distantFuture)
    }

    @Test(arguments: [(3, 8), (11, 1)])
    func dstMorningKeepsWallClockTime(_ month: Int, _ dayOfMonth: Int) throws {
        let r = GymRules(prefs: Prefs(), calendar: Self.ny)
        let now = try #require(Self.ny.date(from: DateComponents(year: 2026, month: month, day: dayOfMonth, hour: 7)))
        let due = r.nextDue(now: now, lastDone: nil, doneToday: 0, skipToday: false)
        let c = Self.ny.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        #expect([c.year, c.month, c.day, c.hour, c.minute] == [2026, month, dayOfMonth, 10, 0])
    }
}
