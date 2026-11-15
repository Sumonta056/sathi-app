import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt running card")
struct ActivityPromptCardTests {
    private static let keepKinds: [PromptKind] = [.whatNow, .center, .stillOnIt, .welcomeBack]

    private func clock(_ date: Date) -> String { Copywriter.trackerClock(date, calendar: Prompt.calendar) }

    private func state(_ kind: PromptKind, calls: PromptCalls = PromptCalls()) -> TrackerPromptState {
        var s = Reasons.withKeep(kind, calls: calls)
        if kind == .whatNow {
            s.lastEnded = Activity(
                kind: .buddy,
                text: "Reading",
                start: Prompt.now.addingTimeInterval(-1800),
                end: Prompt.now.addingTimeInterval(-300)
            )
        }
        if kind == .welcomeBack { s.stoppedByAway = "Coding" }
        return s
    }

    private func stoppedLine() -> String {
        let away = state(.welcomeBack).away
        return away.map { Copywriter.activityPromptStopped("Coding", at: $0.start, cause: $0.cause, calendar: Prompt.calendar) } ?? ""
    }

    private func expected(_ kind: PromptKind) -> (tag: String, name: String, detail: String) {
        let running = "Started " + clock(Prompt.now.addingTimeInterval(-1800)) + " · 30 of 60 min"
        switch kind {
        case .whatNow: return ("LAST ACTIVITY", "Coding", "Reading ended at " + clock(Prompt.now.addingTimeInterval(-300)) + ".")
        case .center, .stillOnIt: return ("NOW RUNNING", "Code review", running)
        case .welcomeBack: return ("BEFORE YOU LEFT", "Coding", stoppedLine())
        case .eventAsk, .todoDue: return ("", "", "")
        }
    }

    @Test(arguments: keepKinds)
    func theCardShowsTheTagTheNameAndTheDetail(_ kind: PromptKind) throws {
        let sut = try Prompt.view(state(kind)).find(viewWithAccessibilityIdentifier: "prompt.card")
        let e = expected(kind)
        let texts = Prompt.texts(sut)
        #expect(texts.contains(e.tag))
        #expect(texts.contains(e.name))
        #expect(texts.contains(e.detail))
    }

    @Test(arguments: keepKinds)
    func theOnlyKeepButtonIsInsideTheCard(_ kind: PromptKind) throws {
        let sut = try Prompt.view(state(kind))
        let card = try sut.find(viewWithAccessibilityIdentifier: "prompt.card")
        #expect(Prompt.has(card, "prompt.keep"))
        #expect(sut.findAll(where: { (try? $0.accessibilityIdentifier()) == "prompt.keep" }).count == 1)
    }

    @Test(arguments: keepKinds)
    func theCardSaysOrSwitchBelowIt(_ kind: PromptKind) throws {
        #expect(try Prompt.hasText(Prompt.view(state(kind)), "or switch to something new"))
    }

    @Test func noCardForAskWithNothingToContinue() throws {
        let sut = try Prompt.view(Prompt.state(.whatNow))
        #expect(!Prompt.has(sut, "prompt.card"))
        #expect(!Prompt.hasText(sut, "or switch to something new"))
    }

    @Test func noCardForAnEvent() throws {
        let sut = try Prompt.view(Reasons.withKeep(.eventAsk))
        #expect(!Prompt.has(sut, "prompt.card"))
        #expect(!Prompt.has(sut, "prompt.keep"))
    }

    private func tapKeepInCard(_ s: TrackerPromptState) throws {
        let card = try Prompt.view(s).find(viewWithAccessibilityIdentifier: "prompt.card")
        try Prompt.tap(card, "prompt.keep")
    }

    @Test func endsCardKeepAsksAgainAfterAskEvery() throws {
        let calls = PromptCalls()
        try tapKeepInCard(state(.stillOnIt, calls: calls))
        #expect(calls.stillOn == [15])
    }

    @Test func lateEndsCardKeepIsStillOnIt() throws {
        let calls = PromptCalls()
        var s = state(.stillOnIt, calls: calls)
        s.waitedMinutes = 12
        try tapKeepInCard(s)
        #expect(calls.calls == ["stillLate"])
        #expect(calls.stillOn.isEmpty)
    }

    @Test func shortcutCardKeepCloses() throws {
        let calls = PromptCalls()
        try tapKeepInCard(state(.center, calls: calls))
        #expect(calls.calls == ["close"])
        #expect(calls.started.isEmpty)
    }

    @Test func backCardKeepGoesBack() throws {
        let calls = PromptCalls()
        try tapKeepInCard(state(.welcomeBack, calls: calls))
        #expect(calls.calls == ["back"])
    }

    @Test func askCardKeepContinuesTheLastActivity() throws {
        let calls = PromptCalls()
        try tapKeepInCard(state(.whatNow, calls: calls))
        #expect(calls.continued == [nil])
        #expect(calls.started.isEmpty)
    }
}
