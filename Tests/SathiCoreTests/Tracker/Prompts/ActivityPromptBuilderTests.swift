import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Activity prompt builder")
struct ActivityPromptBuilderTests {
    private typealias Fix = PromptFixture

    private struct Row {
        var reason: PromptReason
        var tag: String
        var title: String
        var start: String
        var keep: PromptKeep?
        var skip: PromptSkip
    }

    private func row(_ kind: PromptKind) -> Row {
        let ask = "What are you doing now?"
        switch kind {
        case .whatNow: return Row(reason: .ask, tag: "TIME TO CHECK", title: ask, start: "Start", keep: nil, skip: .skip)
        case .center: return Row(reason: .shortcut, tag: "YOU ASKED · ⌃⌥⌘Space", title: ask, start: "Start", keep: nil, skip: .close)
        case .stillOnIt:
            return Row(reason: .ends, tag: "ACTIVITY ENDED", title: "Still on Code review?", start: "Switch", keep: .keepGoing(15), skip: .skip)
        case .welcomeBack:
            return Row(
                reason: .back,
                tag: "WELCOME BACK",
                title: "Welcome back. Where were you?",
                start: "Start",
                keep: .backTo("Code review"),
                skip: .close
            )
        case .eventAsk:
            return Row(reason: .event, tag: "CALENDAR EVENT", title: "Log “Design sync” now?", start: "Log it", keep: nil, skip: .answerNo)
        }
    }

    @Test(arguments: PromptKind.allCases)
    func everyKindShowsItsRowOfTheMappingTable(_ kind: PromptKind) {
        let s = Fix.screen(kind)
        let want = row(kind)
        #expect(s.reason == want.reason)
        #expect(s.tag == want.tag)
        #expect(s.title == want.title)
        #expect(s.startLabel == want.start)
        #expect(s.keep == want.keep)
        #expect(s.skip == want.skip)
    }

    @Test(arguments: PromptKind.allCases)
    func theReasonIsTheColorKeyOfEachKind(_ kind: PromptKind) {
        #expect(PromptReason(kind) == row(kind).reason)
    }

    @Test func keepLabelsUseTheSpecWords() {
        #expect(PromptKeep.continueLast("Spec").label == "Continue Spec")
        #expect(PromptKeep.keep("Spec").label == "Keep Spec")
        #expect(PromptKeep.keepGoing(15).label == "Keep going +15 min")
        #expect(PromptKeep.stillOnLate.label == "Still on it")
        #expect(PromptKeep.backTo("Spec").label == "Back to Spec")
    }

    @Test func endsBeforeTheExpectedEndAsksStillOnIt() {
        let s = Fix.screen(.stillOnIt, now: Fix.at(10, 20))
        #expect(s.tag == "STILL ON IT?")
        #expect(s.timeText == Fix.clock(Fix.at(10)) + " – " + Fix.clock(Fix.at(10, 30)))
    }

    @Test func endsAtTheExpectedEndSaysActivityEnded() {
        let s = Fix.screen(.stillOnIt)
        #expect(s.tag == "ACTIVITY ENDED")
        #expect(s.timeText == Fix.clock(Fix.at(10)) + " – " + Fix.clock(Fix.at(10, 30)))
    }

    @Test func anOpenActivityAsksStillOnItUntilNow() {
        let s = Fix.screen(.stillOnIt, now: Fix.at(11)) { $0.running = Fix.running(length: .open) }
        #expect(s.tag == "STILL ON IT?")
        #expect(s.timeText == Fix.clock(Fix.at(10)) + " – now")
    }

    @Test func endsMessageCountsTheMinutesSoFar() {
        let s = Fix.screen(.stillOnIt, now: Fix.at(10, 42))
        #expect(s.message == "42 min so far. Keep going, or switch.")
    }

    @Test func lateEndsSaysHowLongItWaitedAndKeepsStillOnIt() {
        let s = Fix.screen(.stillOnIt) { $0.waitedMinutes = 7 }
        #expect(s.message == "This question waited 7 min.")
        #expect(s.keep == .stillOnLate)
    }

    @Test func shortcutWhileRunningOffersASwitch() {
        let s = Fix.screen(.center, now: Fix.at(10, 42)) { $0.running = Fix.running() }
        #expect(s.title == "Switch to something new?")
        #expect(s.message == "Keep it, or type a new one to switch.")
        #expect(s.startLabel == "Switch")
        #expect(s.keep == .keep("Code review"))
        #expect(s.timeText == Fix.clock(Fix.at(10, 42)))
    }

    @Test func shortcutWithNothingRunningStartsAndHidesTheStartedLink() {
        let s = Fix.screen(.center) { $0.switchTimes = [Fix.at(10, 30)] }
        #expect(s.message == "Nothing is running.")
        #expect(s.startLabel == "Start")
        #expect(s.keep == nil)
        #expect(s.startedChoices.isEmpty)
    }

    @Test func onlyTheEventHasACalendarNoteAndAFixedStart() {
        for kind in PromptKind.allCases where kind != .eventAsk {
            let s = Fix.screen(kind)
            #expect(s.calendarNote == nil)
            #expect(s.fixedStart == nil)
            #expect(!s.showsWhere || kind == .welcomeBack)
        }
    }
}
