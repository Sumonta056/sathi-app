import Foundation
import SathiCore
import Testing

@Suite("Calendar chips")
struct CalendarChipsTests {
    private func cals(_ count: Int) -> [CalendarChoice] {
        (1 ... count).map { CalendarChoice(id: "c\($0)", title: "Cal \($0)", account: "iCloud", colorHex: 0x4CC3F5) }
    }

    private func ids(_ list: [CalendarChoice]) -> [String] { list.map(\.id) }

    @Test func theLimitIsFive() {
        #expect(Limits.promptCalendarsShown == 5)
    }

    @Test func fewCalendarsAreAllShownInOrder() {
        #expect(ids(CalendarChips.shown(cals(3), picked: nil, all: false)) == ["c1", "c2", "c3"])
        #expect(ids(CalendarChips.shown(cals(5), picked: nil, all: false)) == ["c1", "c2", "c3", "c4", "c5"])
    }

    @Test func manyCalendarsShowTheFirstFive() {
        #expect(ids(CalendarChips.shown(cals(8), picked: nil, all: false)) == ["c1", "c2", "c3", "c4", "c5"])
    }

    @Test func allShowsEveryCalendar() {
        #expect(ids(CalendarChips.shown(cals(8), picked: nil, all: true)) == ["c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8"])
    }

    @Test func aPickedCalendarAmongTheFirstFiveChangesNothing() {
        #expect(ids(CalendarChips.shown(cals(8), picked: "c2", all: false)) == ["c1", "c2", "c3", "c4", "c5"])
    }

    @Test func aPickedCalendarPastTheLimitTakesTheLastPlace() {
        #expect(ids(CalendarChips.shown(cals(8), picked: "c8", all: false)) == ["c1", "c2", "c3", "c4", "c8"])
    }

    @Test func anUnknownPickedIDShowsTheFirstFive() {
        #expect(ids(CalendarChips.shown(cals(8), picked: "gone", all: false)) == ["c1", "c2", "c3", "c4", "c5"])
    }

    @Test(arguments: [1, 3, 5, 7])
    func neverMoreThanTheLimit(_ limit: Int) {
        let shown = CalendarChips.shown(cals(8), picked: "c8", all: false, limit: limit)
        #expect(shown.count == limit)
        #expect(shown.last?.id == "c8")
    }

    @Test func aUniqueTitleIsTheLabel() {
        let list = cals(3)
        #expect(CalendarChips.label(list[1], in: list) == "Cal 2")
    }

    @Test func aSharedTitleAddsTheAccount() {
        let icloud = CalendarChoice(id: "a", title: "Calendar", account: "iCloud", colorHex: 0)
        let google = CalendarChoice(id: "b", title: "Calendar", account: "Google", colorHex: 0)
        let work = CalendarChoice(id: "c", title: "Work", account: "Google", colorHex: 0)
        let list = [icloud, google, work]
        #expect(CalendarChips.label(icloud, in: list) == "Calendar · iCloud")
        #expect(CalendarChips.label(google, in: list) == "Calendar · Google")
        #expect(CalendarChips.label(work, in: list) == "Work")
    }

    @Test func aSharedTitleWithNoAccountIsJustTheTitle() {
        let a = CalendarChoice(id: "a", title: "Calendar", account: "", colorHex: 0)
        let b = CalendarChoice(id: "b", title: "Calendar", account: "Google", colorHex: 0)
        #expect(CalendarChips.label(a, in: [a, b]) == "Calendar")
    }

    @Test func moreSaysHowManyAreHidden() {
        #expect(Copywriter.activityPromptCalendarMore(3) == "+3 more")
        #expect(Copywriter.activityPromptCalendarMore(12) == "+12 more")
    }
}
