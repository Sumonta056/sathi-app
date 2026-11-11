import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Today page")
struct TodayPageTests {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .current
        return c
    }()

    private func clock(_ date: Date) -> String { Copywriter.trackerClock(date, calendar: cal) }

    private func buddy(
        _ id: HabitID, total: String = "0", goal: Int = 8, unit: String = "glasses", status: TodayBuddyStatus
    ) -> TodayBuddy {
        TodayBuddy(habit: id, total: total, goal: goal, unit: unit, progress: 0.5, status: status)
    }

    private func card(_ b: TodayBuddy) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodayBuddyCard(buddy: b, calendar: cal), EngineHarness()).inspect()
    }

    private func running(_ h: EngineHarness) -> TodayNow {
        .running(minutes: 42, text: "Code review", category: "Work", since: day(2026, 3, 4, 9, 18), nextAsk: day(2026, 3, 4, 10, 30))
    }

    @Test func runningNowCardShowsTheActivity() throws {
        let h = EngineHarness()
        let sut = try hosted(TodayNowCard(now: running(h), calendar: cal), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "NOW") }
        #expect(throws: Never.self) { try sut.find(text: "42m") }
        #expect(throws: Never.self) { try sut.find(text: "Code review") }
        #expect(throws: Never.self) {
            try sut.find(text: "Work · since \(clock(day(2026, 3, 4, 9, 18))) · Still on it? at \(clock(day(2026, 3, 4, 10, 30)))")
        }
    }

    @Test func switchOpensTheActivityPrompt() throws {
        let h = EngineHarness.tracker()
        h.engine.startActivity(ActivityDraft(text: "Code review", length: .minutes(30)))
        let sut = try hosted(TodayNowCard(now: running(h), calendar: cal), h).inspect()
        try Find.button(sut, holding: "Switch").tap()
        #expect(h.tracker.prompt?.kind == .center)
    }

    @Test func stopEndsTheRunningActivity() throws {
        let h = EngineHarness.tracker()
        h.engine.startActivity(ActivityDraft(text: "Code review", length: .minutes(30)))
        let sut = try hosted(TodayNowCard(now: running(h), calendar: cal), h).inspect()
        try Find.button(sut, holding: "Stop").tap()
        #expect(h.tracker.prompt?.kind == .whatNow)
    }

    @Test func idleNowCardOffersToLogAnActivity() throws {
        let h = EngineHarness.tracker()
        let sut = try hosted(TodayNowCard(now: .idle(nextAsk: day(2026, 3, 4, 10, 30)), calendar: cal), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Not tracking now") }
        #expect(throws: Never.self) { try sut.find(text: "Next ask \(clock(day(2026, 3, 4, 10, 30)))") }
        try Find.button(sut, holding: "Log activity").tap()
        #expect(h.tracker.prompt?.kind == .center)
    }

    @Test func offNowCardTurnsOnTheTracker() throws {
        let h = EngineHarness()
        let sut = try hosted(TodayNowCard(now: .off, calendar: cal), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todayTrackerOff) }
        try Find.button(sut, holding: "Turn on").tap()
        #expect(h.presenter.calls.last == .showMain(.settings(.tracker)))
    }

    @Test func gridShowsFourBuddyCards() throws {
        let buddies = HabitID.allCases.map { buddy($0, status: .off) }
        let sut = try hosted(TodayBuddyGrid(buddies: buddies, calendar: cal), EngineHarness()).inspect()
        #expect(sut.findAll(TodayBuddyCard.self).count == 4)
    }

    @Test func buddyCardShowsNameAndProgress() throws {
        let sut = try card(buddy(.water, total: "5", status: .met))
        #expect(throws: Never.self) { try sut.find(text: "Fota") }
        #expect(throws: Never.self) { try sut.find(text: "5") }
        #expect(throws: Never.self) { try sut.find(text: " / 8 glasses") }
    }

    @Test func metBuddyShowsGoalMet() throws {
        #expect(throws: Never.self) { try card(buddy(.reading, status: .met)).find(text: "✓ Goal met") }
    }

    @Test func nextBuddyShowsTheTime() throws {
        let t = day(2026, 3, 4, 15, 30)
        #expect(throws: Never.self) { try card(buddy(.water, status: .next(t))).find(text: "Next at \(clock(t))") }
    }

    @Test func gymShowsTheSession() throws {
        let t = day(2026, 3, 4, 16, 40)
        let sut = try card(buddy(.gym, status: .gymSession(3, of: 4, t)))
        #expect(throws: Never.self) { try sut.find(text: "Session 3 of 4 at \(clock(t))") }
    }

    @Test func otherStatusesUseTheMenuWords() throws {
        let t = day(2026, 3, 4, 16, 40)
        let cases: [(TodayBuddyStatus, String)] = [
            (.off, "Off"), (.dayOff, "Day off"), (.noReminder, "No reminder"), (.dueNow, "Due now"),
            (.paused, "Paused"), (.snoozed(t), "Snoozed until \(clock(t))")
        ]
        for (status, text) in cases {
            #expect(throws: Never.self) { try card(buddy(.water, status: status)).find(text: text) }
        }
    }

    @Test func breatheNowOnlyOnShanti() throws {
        let t = day(2026, 3, 4, 16, 0)
        let sut = try hosted(
            TodayBuddyGrid(buddies: HabitID.allCases.map { buddy($0, status: .next(t)) }, calendar: cal), EngineHarness()
        ).inspect()
        #expect(sut.findAll(ViewType.Button.self, where: { (try? $0.labelView().find(text: "Breathe now")) != nil }).count == 1)
        #expect(throws: Never.self) { try card(buddy(.meditation, status: .next(t))).find(text: "Breathe now") }
        #expect(try Find.lacks(card(buddy(.water, status: .next(t))), text: "Breathe now"))
    }

    @Test func breatheNowStartsTheSession() throws {
        let h = EngineHarness()
        let b = buddy(.meditation, status: .next(day(2026, 3, 4, 16, 0)))
        try hosted(TodayBuddyCard(buddy: b, calendar: cal), h).inspect().find(button: "Breathe now").tap()
        #expect(h.presenter.calls.contains(.showSession(.meditation)))
    }

    @Test func comingUpListsRows() throws {
        let a = ComingUpItem(kind: .trackerAsk, title: "Still on it?", time: day(2026, 3, 4, 15, 10))
        let b = ComingUpItem(kind: .daySummary, title: "Day summary", time: day(2026, 3, 4, 22))
        let sut = try hosted(TodayComingUp(items: [a, b], calendar: cal), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Coming up") }
        #expect(throws: Never.self) { try sut.find(text: clock(a.time)) }
        #expect(throws: Never.self) { try sut.find(text: "Day summary") }
        #expect(Find.lacks(sut, text: "Nothing more today."))
    }

    @Test func emptyComingUpSaysNothingMore() throws {
        let sut = try hosted(TodayComingUp(items: [], calendar: cal), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Nothing more today.") }
    }

    @Test func soFarOffShowsTheOffText() throws {
        let sut = try hosted(TodaySoFarCard(sofar: .off, categories: [], calendar: cal), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Today so far") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todaySoFarOffHint) }
    }

    @Test func soFarOnShowsLoggedTimeAndCategories() throws {
        let hours = DateInterval(start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 18))
        let sofar = TodaySoFar(
            isOn: true, hours: hours, segments: [], logged: 3 * 3600,
            categories: [ActivityCategoryTotal(name: "Work", isNamed: true, seconds: 3 * 3600, percent: 100)]
        )
        let sut = try hosted(TodaySoFarCard(sofar: sofar, categories: [], calendar: cal), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todayLogged(3 * 3600)) }
        #expect(throws: Never.self) { try sut.find(text: "Work") }
        #expect(throws: Never.self) { try sut.find(ActivityRibbon.self) }
    }

    @Test func headerShowsDateAndGreeting() throws {
        let sut = try hosted(TodayHeader(dateLine: "TUESDAY, 4 MARCH", greeting: "Good morning"), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "TUESDAY, 4 MARCH") }
        #expect(throws: Never.self) { try sut.find(text: "Good morning") }
        #expect(throws: Never.self) { try sut.find(BreakMenu.self) }
    }

    @Test func quickReminderButtonOpensTheAddPopup() throws {
        let h = EngineHarness()
        let sut = try hosted(TodayHeader(dateLine: "X", greeting: "Y"), h).inspect()
        try Find.button(sut, holding: "Quick reminder").tap()
        #expect(h.presenter.calls.last == .showQuickAdd)
    }
}
