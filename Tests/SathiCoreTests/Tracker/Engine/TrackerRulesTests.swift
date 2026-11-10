import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Tracker rules")
struct TrackerRulesTests {
    private let hours = TrackerHours(prefs: TrackerPrefs(), calendar: .current)

    @Test func hoursAreNineToSixOnWeekdaysOnly() {
        #expect(hours.isInside(wed(9)))
        #expect(hours.isInside(wed(17, 59)))
        #expect(!hours.isInside(wed(8, 59)))
        #expect(!hours.isInside(wed(18)))
        #expect(!hours.isInside(day(2026, 3, 7, 10)))
    }

    @Test func aDayOffIsNotATrackerDay() {
        var p = TrackerPrefs()
        p.daysOff = [DayKey(wed(10), calendar: .current)]
        #expect(!TrackerHours(prefs: p, calendar: .current).isInside(wed(10)))
    }

    @Test func nextStartSkipsTheWeekend() {
        #expect(hours.nextStart(after: wed(8)) == wed(9))
        #expect(hours.nextStart(after: day(2026, 3, 6, 10)) == day(2026, 3, 9, 9))
    }

    @Test func clipKeepsOnlyTimeInsideTrackerHours() {
        let parts = hours.clip(DateInterval(start: wed(7), end: day(2026, 3, 5, 10)))
        #expect(parts == [DateInterval(start: wed(9), end: wed(18)), DateInterval(start: day(2026, 3, 5, 9), end: day(2026, 3, 5, 10))])
    }

    @Test func switchChipsAreFiveMinutesApartFromTheLastAnswerToNow() {
        let chips = SwitchTimes.chips(from: wed(10, 2), to: wed(10, 17), calendar: .current)
        #expect(chips == [wed(10, 2), wed(10, 5), wed(10, 10), wed(10, 15), wed(10, 17)])
    }

    @Test func switchChipsWithNoTimeLeftAreOnlyNow() {
        #expect(SwitchTimes.chips(from: wed(10), to: wed(10), calendar: .current) == [wed(10)])
    }

    @Test(arguments: [(ActivityLength.minutes(30), 0, 30), (.minutes(30), 5, 35), (.minutes(15), 15, 30), (.open, 0, 15), (.open, 5, 15)])
    func firstAskIsStartPlusLengthPlusOffsetOrAskEveryForOpen(length: ActivityLength, offset: Int, minutes: Int) {
        let got = AskTime.first(start: wed(10), length: length, offsetMinutes: offset, askEveryMinutes: 15)
        #expect(got == wed(10, minutes))
    }

    @Test func awayEndIsTheEarlierOfAwayStartAndConfirmedUntil() {
        #expect(AskTime.awayEnd(start: wed(10), confirmedUntil: wed(10, 30), awayStart: wed(10, 50)) == wed(10, 30))
        #expect(AskTime.awayEnd(start: wed(10), confirmedUntil: wed(10, 30), awayStart: wed(10, 20)) == wed(10, 20))
        #expect(AskTime.awayEnd(start: wed(10), confirmedUntil: wed(10, 30), awayStart: wed(9)) == wed(10))
    }

    @Test func lateMeansFiveMinutesOrMore() {
        #expect(AskTime.waitedMinutes(shownAt: wed(10), now: wed(10, 4, s: 59)) == nil)
        #expect(AskTime.waitedMinutes(shownAt: wed(10), now: wed(10, 7)) == 7)
    }

    @Test func recentsAreNewestFirstUniqueAndOnlyWork() {
        let items = [
            Activity(text: "A", category: "Coding", start: wed(9), end: wed(9, 30)),
            Activity(kind: .away, text: "Away", start: wed(9, 30), end: wed(10)),
            Activity(text: "B", start: wed(10), end: wed(10, 30)),
            Activity(text: "A", category: "Coding", start: wed(11), end: wed(11, 20)),
            Activity(kind: .buddy, text: "Reading", start: wed(12), end: wed(12, 10))
        ]
        let got = RecentList.recents(items)
        #expect(got.map(\.text) == ["A", "B"])
        #expect(got.first?.length == 20 * Timing.minute)
    }

    @Test func theRecentMaxIsTen() {
        #expect(Limits.recentMax == 10)
    }

    @Test func recentsStopAtTenAndKeepTheNewest() {
        let items = (0 ..< 12).map { Activity(text: "T\($0)", start: wed(9, $0 * 5), end: wed(9, $0 * 5 + 2)) }
        let got = RecentList.recents(items)
        #expect(got.count == 10)
        #expect(got.map(\.text) == ["T11", "T10", "T9", "T8", "T7", "T6", "T5", "T4", "T3", "T2"])
    }

    @Test func theSameTextWithAnotherCategoryIsASecondRecent() {
        let items = [
            Activity(text: "A", category: "Coding", start: wed(9), end: wed(9, 30)),
            Activity(text: "A", category: "Review", start: wed(10), end: wed(10, 30)),
            Activity(text: "A", category: "Coding", start: wed(11), end: wed(11, 30))
        ]
        let got = RecentList.recents(items)
        #expect(got.map(\.text) == ["A", "A"])
        #expect(got.map(\.category) == ["Coding", "Review"])
    }

    @Test func editCheckRefusesEmptyShortAndOverlap() {
        let other = [DateInterval(start: wed(10), end: wed(11))]
        #expect(ActivityEditCheck.problem(ActivityEdit(text: " ", category: nil, start: wed(12), end: wed(13)), others: other) == .emptyText)
        #expect(ActivityEditCheck.problem(ActivityEdit(text: "x", category: nil, start: wed(12), end: wed(12, 0, s: 59)), others: other) == .tooShort)
        #expect(ActivityEditCheck.problem(ActivityEdit(text: "x", category: nil, start: wed(10, 30), end: wed(12)), others: other) == .overlap)
        #expect(ActivityEditCheck.problem(ActivityEdit(text: "x", category: nil, start: wed(11), end: wed(12)), others: other) == nil)
    }
}
