import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Today cards")
struct TodayCardsTests {
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
        let h = EngineHarness()
        return try hosted(TodayBuddyCard(e: h.engine, buddy: b, calendar: cal), h).inspect()
    }

    private func running(_ h: EngineHarness) -> TodayNow {
        .running(minutes: 42, text: "Code review", category: "Work", since: day(2026, 3, 4, 9, 18), nextAsk: day(2026, 3, 4, 10, 30))
    }

    @Test func runningNowCardShowsTheActivity() throws {
        let h = EngineHarness()
        let sut = try hosted(TodayNowCard(e: h.engine, now: running(h), calendar: cal), h).inspect()
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
        let sut = try hosted(TodayNowCard(e: h.engine, now: running(h), calendar: cal), h).inspect()
        try Find.button(sut, holding: "Switch").tap()
        #expect(h.tracker.prompt?.kind == .center)
    }

    @Test func stopEndsTheRunningActivity() throws {
        let h = EngineHarness.tracker()
        h.engine.startActivity(ActivityDraft(text: "Code review", length: .minutes(30)))
        let sut = try hosted(TodayNowCard(e: h.engine, now: running(h), calendar: cal), h).inspect()
        try Find.button(sut, holding: "Stop").tap()
        #expect(h.tracker.prompt?.kind == .whatNow)
    }

    @Test func idleNowCardOffersToLogAnActivity() throws {
        let h = EngineHarness.tracker()
        let sut = try hosted(TodayNowCard(e: h.engine, now: .idle(nextAsk: day(2026, 3, 4, 10, 30)), calendar: cal), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Not tracking now") }
        #expect(throws: Never.self) { try sut.find(text: "Next ask \(clock(day(2026, 3, 4, 10, 30)))") }
        try Find.button(sut, holding: "Log activity").tap()
        #expect(h.tracker.prompt?.kind == .center)
    }

    @Test func offNowCardTurnsOnTheTracker() throws {
        let h = EngineHarness()
        let sut = try hosted(TodayNowCard(e: h.engine, now: .off, calendar: cal), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todayTrackerOff) }
        try Find.button(sut, holding: "Turn on").tap()
        #expect(h.presenter.calls.last == .showMain(.settings(.tracker)))
    }

    @Test func gridShowsFourBuddyCards() throws {
        let buddies = HabitID.allCases.map { buddy($0, status: .off) }
        let h = EngineHarness()
        let sut = try hosted(TodayBuddyGrid(e: h.engine, buddies: buddies, calendar: cal), h).inspect()
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
        let h = EngineHarness()
        let sut = try hosted(
            TodayBuddyGrid(e: h.engine, buddies: HabitID.allCases.map { buddy($0, status: .next(t)) }, calendar: cal), h
        ).inspect()
        #expect(sut.findAll(ViewType.Button.self, where: { (try? $0.labelView().find(text: "Breathe now")) != nil }).count == 1)
        #expect(throws: Never.self) { try card(buddy(.meditation, status: .next(t))).find(text: "Breathe now") }
        #expect(try Find.lacks(card(buddy(.water, status: .next(t))), text: "Breathe now"))
    }

    @Test func breatheNowStartsTheSession() throws {
        let h = EngineHarness()
        let b = buddy(.meditation, status: .next(day(2026, 3, 4, 16, 0)))
        try hosted(TodayBuddyCard(e: h.engine, buddy: b, calendar: cal), h).inspect().find(button: "Breathe now").tap()
        #expect(h.presenter.calls.contains(.showSession(.meditation)))
    }
}
