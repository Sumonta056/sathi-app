import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
enum Reasons {
    static func running(minutesAgo: Double = 30, length: ActivityLength = .minutes(60)) -> RunningActivity {
        let start = Prompt.now.addingTimeInterval(-minutesAgo * 60)
        return RunningActivity(text: "Code review", category: "Review", start: start, expectedLength: length, askAt: Prompt.now)
    }

    static func withKeep(_ kind: PromptKind, calls: PromptCalls = PromptCalls()) -> TrackerPromptState {
        Prompt.state(kind, calls: calls) { s in
            s.askEveryMinutes = 15
            switch kind {
            case .whatNow: s.resume = ActivityDraft(text: "Coding")
            case .center, .stillOnIt: s.running = running()
            case .welcomeBack:
                s.lastActivity = ActivityDraft(text: "Coding")
                s.away = AwaySpan(start: Prompt.now.addingTimeInterval(-2100), end: Prompt.now, cause: .asleep)
            case .todoDue:
                s.todos = [makeTodo("a", "Write report")]
                s.running = running()
            case .eventAsk:
                s.event = Prompt.event()
                s.eventCalendarTitle = "Work"
                s.draft.category = "Meeting"
            }
        }
    }
}

@MainActor
@Suite("Activity prompt reasons")
struct ActivityPromptReasonTests {
    private struct Expected {
        let tag: String
        let title: String
        let start: String
        let keep: String?
    }

    private static func expected(_ kind: PromptKind) -> Expected {
        switch kind {
        case .whatNow: Expected(tag: "TIME TO CHECK", title: "What are you doing now?", start: "Start", keep: "Continue Coding")
        case .center: Expected(tag: "YOU ASKED", title: "Switch to something new?", start: "Switch", keep: "Keep Code review")
        case .stillOnIt: Expected(tag: "STILL ON IT?", title: "Still on Code review?", start: "Switch", keep: "Keep going +15 min")
        case .welcomeBack: Expected(tag: "WELCOME BACK", title: "Welcome back. Where were you?", start: "Start", keep: "Back to Coding")
        case .todoDue: Expected(tag: "TO-DO DUE", title: "Write report", start: "Switch to it", keep: "Keep Code review")
        case .eventAsk: Expected(tag: "CALENDAR EVENT", title: "Log “Standup” now?", start: "Log it", keep: nil)
        }
    }

    @Test(arguments: PromptKind.allCases)
    func theHeaderShowsTheTagAndTheTitle(_ kind: PromptKind) throws {
        let sut = try Prompt.view(Reasons.withKeep(kind))
        let e = Self.expected(kind)
        #expect(Prompt.hasText(sut, e.tag))
        #expect(Prompt.hasText(sut, e.title))
    }

    @Test(arguments: PromptKind.allCases)
    func startAndKeepUseTheirLabels(_ kind: PromptKind) throws {
        let sut = try Prompt.view(Reasons.withKeep(kind))
        let e = Self.expected(kind)
        #expect(try Prompt.buttonText(sut, "tracker.start") == [e.start])
        #expect(Prompt.has(sut, "prompt.keep") == (e.keep != nil))
        if let keep = e.keep { #expect(try Prompt.buttonText(sut, "prompt.keep") == [keep]) }
    }

    @Test(arguments: PromptKind.allCases)
    func everyReasonHasTheCloseCross(_ kind: PromptKind) throws {
        let sut = try Prompt.view(Reasons.withKeep(kind))
        #expect(Prompt.has(sut, "prompt.dismiss"))
    }

    @Test(arguments: [PromptKind.whatNow, .center, .stillOnIt, .welcomeBack])
    func noKeepWithoutSomethingToKeep(_ kind: PromptKind) throws {
        let sut = try Prompt.view(Prompt.state(kind))
        #expect(!Prompt.has(sut, "prompt.keep"))
    }

    @Test func theEndedTagShowsAfterTheExpectedEnd() throws {
        let s = Prompt.state(.stillOnIt) { $0.running = Reasons.running(minutesAgo: 70) }
        #expect(try Prompt.hasText(Prompt.view(s), "ACTIVITY ENDED"))
    }

    @Test func theMessageLineIsTheScreenMessage() throws {
        let s = Reasons.withKeep(.center)
        #expect(try Prompt.hasText(Prompt.view(s), ActivityPromptBuilder.screen(s).message))
    }

    @Test func theLateKeepSaysStillOnIt() throws {
        let s = Prompt.state(.stillOnIt) {
            $0.running = Reasons.running()
            $0.waitedMinutes = 12
        }
        #expect(try Prompt.buttonText(Prompt.view(s), "prompt.keep") == ["Still on it"])
    }
}
