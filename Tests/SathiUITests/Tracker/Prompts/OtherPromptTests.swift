import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Center prompt")
struct CenterPromptTests {
    @Test func listsEveryRecentInTheDropdown() throws {
        let recents = (0 ..< 10).map { RecentActivity(text: "R\($0)", category: nil, length: 60) }
        let s = Prompt.state(.center) { $0.recents = recents }
        let list = try Prompt.recentList(CenterPromptView(state: s).inspect())
        #expect(Prompt.texts(list).filter { $0.hasPrefix("R") } == (0 ..< 10).map { "R\($0)" })
        #expect(Prompt.ids(list, prefix: "tracker.recent.chip").count == 10)
    }

    @Test func runningEventIsTheFirstRowOfTheDropdown() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.center, calls: calls) {
            $0.runningEvent = Prompt.event()
            $0.recents = [RecentActivity(text: "R0", category: nil, length: 60)]
        }
        let list = try Prompt.recentList(CenterPromptView(state: s).inspect())
        #expect(Prompt.ids(list, prefix: "tracker.").first { $0.hasSuffix(".chip") } == "tracker.event.chip")
        try Prompt.tap(list, "tracker.event.chip")
        #expect(calls.started.first?.0.text == "Standup")
        #expect(calls.started.first?.0.sourceEventID == "e1")
        #expect(calls.started.map { $0.1 == nil } == [true])
    }

    @Test func alwaysShowsForCalendarAndQuiet() throws {
        let sut = try CenterPromptView(state: Prompt.state(.center)).inspect()
        #expect(Prompt.has(sut, "tracker.for.15 min"))
        #expect(Prompt.has(sut, "tracker.calendar.check"))
        #expect(Prompt.has(sut, "tracker.quiet"))
    }

    @Test func startSendsNoSwitchTimeAndCloseCloses() throws {
        let calls = PromptCalls()
        let sut = try CenterPromptView(state: Prompt.state(.center, calls: calls)).inspect()
        try Prompt.tap(sut, "tracker.start")
        #expect(calls.started.map { $0.1 == nil } == [true])
        try Prompt.tap(sut, "tracker.close")
        #expect(calls.calls == ["close"])
    }
}

@MainActor
@Suite("Still on it popup")
struct StillOnItPopupTests {
    private func state(_ calls: PromptCalls, late: Int? = nil) -> TrackerPromptState {
        Prompt.state(.stillOnIt, calls: calls) {
            $0.running = RunningActivity(
                text: "Write spec", category: "Coding", start: Prompt.now.addingTimeInterval(-1800),
                expectedLength: .minutes(30), askAt: Prompt.now
            )
            $0.waitedMinutes = late
        }
    }

    @Test func onTimeButtons() throws {
        let calls = PromptCalls()
        let sut = try StillOnItPopup(state: state(calls)).inspect()
        try Prompt.tap(sut, "tracker.still")
        try Prompt.tap(sut, "tracker.in.5")
        try Prompt.tap(sut, "tracker.in.30")
        try Prompt.tap(sut, "tracker.done")
        try Prompt.tap(sut, "tracker.skip")
        #expect(calls.stillOn == [nil, 5, 30])
        #expect(calls.calls == ["done"])
        #expect(calls.skipped.count == 1)
        #expect(!Prompt.has(sut, "tracker.stillLate"))
    }

    @Test func lateShowsWaitedAndTwoAnswers() throws {
        let calls = PromptCalls()
        let sut = try StillOnItPopup(state: state(calls, late: 7)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "This question waited 7 min.") }
        try Prompt.tap(sut, "tracker.stillLate")
        try Prompt.tap(sut, "tracker.done")
        #expect(calls.calls == ["stillLate", "done"])
        #expect(!Prompt.has(sut, "tracker.still"))
        #expect(!Prompt.has(sut, "tracker.skip"))
    }

    @Test func titleIsTheRunningText() throws {
        let sut = try StillOnItPopup(state: state(PromptCalls())).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Write spec") }
    }
}

@MainActor
@Suite("Welcome back view")
struct WelcomeBackViewTests {
    private func state(_ calls: PromptCalls, cause: AwayCause = .locked) -> TrackerPromptState {
        Prompt.state(.welcomeBack, calls: calls) {
            $0.lastActivity = ActivityDraft(text: "Coding")
            $0.away = AwaySpan(start: Prompt.now.addingTimeInterval(-3600), end: Prompt.now, cause: cause)
        }
    }

    @Test func backToLastAndPlaceChips() throws {
        let calls = PromptCalls()
        let sut = try WelcomeBackView(state: state(calls)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Back to Coding") }
        try Prompt.tap(sut, "tracker.back")
        try Prompt.tap(sut, "tracker.place.lunch")
        #expect(calls.calls == ["back"])
        #expect(calls.places == [.lunch])
    }

    @Test func iWasHereOnlyAfterIdle() throws {
        let locked = try WelcomeBackView(state: state(PromptCalls())).inspect()
        #expect(!Prompt.has(locked, "tracker.here"))
        let calls = PromptCalls()
        let idle = try WelcomeBackView(state: state(calls, cause: .idle)).inspect()
        try Prompt.tap(idle, "tracker.here")
        #expect(calls.calls == ["here"])
    }

    @Test func whileAwayRowsHaveNotAttending() throws {
        let calls = PromptCalls()
        let row = Activity(kind: .event, text: "Standup", start: Prompt.now, end: Prompt.now.addingTimeInterval(900), sourceEventID: "e1")
        let s = Prompt.state(.welcomeBack, calls: calls) {
            $0.away = AwaySpan(start: Prompt.now, end: Prompt.now, cause: .locked)
            $0.loggedWhileAway = [row]
        }
        let sut = try WelcomeBackView(state: s).inspect()
        #expect(throws: Never.self) { try sut.find(text: "WHILE YOU WERE AWAY") }
        try Prompt.tap(sut, "tracker.notAttending")
        #expect(calls.notAttending == ["e1"])
    }

    @Test func noWhileAwaySectionWhenEmpty() throws {
        let sut = try WelcomeBackView(state: state(PromptCalls())).inspect()
        #expect((try? sut.find(text: "WHILE YOU WERE AWAY")) == nil)
    }

    @Test func somethingNewIsAButtonThatRevealsTheField() throws {
        let sut = try WelcomeBackView(state: state(PromptCalls())).inspect()
        #expect(Prompt.has(sut, "tracker.new"))
        #expect(sut.findAll(LazyTextField.self).isEmpty)
    }
}

@MainActor
@Suite("Event ask popup")
struct EventAskPopupTests {
    @Test func yesAndNo() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.eventAsk, calls: calls) { $0.event = Prompt.event() }
        let sut = try EventAskPopup(state: s).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Standup started. Log it?") }
        try Prompt.tap(sut, "tracker.yes")
        try Prompt.tap(sut, "tracker.no")
        #expect(calls.answers == [true, false])
    }
}
