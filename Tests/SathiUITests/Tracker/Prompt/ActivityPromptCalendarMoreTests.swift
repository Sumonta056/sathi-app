import Foundation
@testable import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt calendar more")
struct ActivityPromptCalendarMoreTests {
    private let eight = (1 ... 8).map { CalendarChoice(id: "c\($0)", title: "Cal \($0)", account: "iCloud", colorHex: 0x4CC3F5) }

    private func state(picked: String? = nil) -> TrackerPromptState {
        Prompt.state(.whatNow) {
            $0.calendars = eight
            $0.draft.calendarID = picked
        }
    }

    @Test func eightCalendarsShowFiveNoneAndMore() throws {
        let sut = try Prompt.view(state())
        for i in 1 ... 5 {
            #expect(Prompt.has(sut, "prompt.calendar.c\(i)"))
        }
        #expect(!Prompt.has(sut, "prompt.calendar.c6"))
        #expect(!Prompt.has(sut, "prompt.calendar.c8"))
        #expect(Prompt.has(sut, "prompt.calendar.none"))
        #expect(Prompt.has(sut, "prompt.calendar.more"))
        #expect(try Prompt.buttonText(sut, "prompt.calendar.more").contains("+3 more"))
    }

    @Test func moreShowsEveryCalendar() throws {
        let s = state()
        let model = ActivityPromptModel(s)
        #expect(!model.showsAllCalendars)
        try Prompt.tap(Prompt.view(s, model: model), "prompt.calendar.more")
        #expect(model.showsAllCalendars)
        let sut = try Prompt.view(s, model: model)
        for i in 1 ... 8 {
            #expect(Prompt.has(sut, "prompt.calendar.c\(i)"))
        }
        #expect(!Prompt.has(sut, "prompt.calendar.more"))
    }

    @Test func aPickedCalendarPastFiveHasABox() throws {
        let sut = try Prompt.view(state(picked: "c8"))
        #expect(Prompt.has(sut, "prompt.calendar.c8"))
        #expect(try Prompt.boxIsOn(sut, "prompt.calendar.c8"))
        #expect(!Prompt.has(sut, "prompt.calendar.c5"))
    }

    @Test func twoCalendarsWithOneTitleNameTheirAccounts() throws {
        let s = Prompt.state(.whatNow) {
            $0.calendars = [
                CalendarChoice(id: "a", title: "Calendar", account: "iCloud", colorHex: 0x4CC3F5),
                CalendarChoice(id: "b", title: "Calendar", account: "Google", colorHex: 0x34A853)
            ]
        }
        let sut = try Prompt.view(s)
        #expect(try Prompt.buttonText(sut, "prompt.calendar.a").contains("Calendar · iCloud"))
        #expect(try Prompt.buttonText(sut, "prompt.calendar.b").contains("Calendar · Google"))
    }

    @Test func twoCalendarsHaveNoMore() throws {
        let s = Prompt.state(.whatNow) {
            $0.calendars = Array(eight.prefix(2))
        }
        #expect(try !Prompt.has(Prompt.view(s), "prompt.calendar.more"))
    }

    @Test func aShortScreenScrollsTheFormButNotTheFooter() throws {
        let sut = try ActivityPromptView(state: state(), model: nil, visibleHeight: 700).inspect()
        let scroll = try sut.find(ViewType.ScrollView.self)
        #expect(Prompt.has(scroll, "prompt.field"))
        #expect(!Prompt.has(scroll, "tracker.start"))
        #expect(Prompt.has(sut, "tracker.start"))
    }
}
