import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Activity prompt messages")
struct ActivityPromptMessageTests {
    private typealias Fix = PromptFixture

    @Test func askShowsTheAskTime() {
        #expect(Fix.screen(.whatNow).timeText == Fix.clock(Fix.at(10, 30)))
    }

    @Test func askWithNoLastActivitySaysNothingIsRunning() {
        #expect(Fix.screen(.whatNow).message == "Nothing is running.")
    }

    @Test func askNamesTheLastActivityAndItsEnd() {
        let s = Fix.screen(.whatNow) { $0.lastEnded = Activity(text: "Standup", start: Fix.at(10), end: Fix.at(10, 20)) }
        #expect(s.message == "Nothing is running. Standup ended at " + Fix.clock(Fix.at(10, 20)) + ".")
    }

    @Test func askAfterDoneNamesTheDoneActivity() {
        let s = Fix.screen(.whatNow) {
            $0.running = Fix.running()
            $0.doneAt = Fix.at(10, 25)
        }
        #expect(s.message == "Nothing is running. Code review ended at " + Fix.clock(Fix.at(10, 25)) + ".")
    }

    @Test func askAfterABuddySessionNamesTheSessionAndOffersContinue() {
        let s = Fix.screen(.whatNow) {
            $0.resume = ActivityDraft(text: "Spec")
            $0.lastEnded = Activity(kind: .buddy, text: "Reading", start: Fix.at(10), end: Fix.at(10, 30))
        }
        #expect(s.message == "Reading ended at " + Fix.clock(Fix.at(10, 30)) + ".")
        #expect(s.keep == .continueLast("Spec"))
    }

    @Test func startedChoicesComeFromTheSwitchTimes() {
        let times = [Fix.at(10, 10), Fix.at(10, 15), Fix.at(10, 30)]
        #expect(Fix.screen(.whatNow) { $0.switchTimes = times }.startedChoices == times)
        #expect(Fix.screen(.whatNow) { $0.switchTimes = [Fix.at(10, 30)] }.startedChoices.isEmpty)
        #expect(Fix.screen(.whatNow).startedChoices.isEmpty)
    }

    @Test(arguments: [
        (AwayCause.asleep, "when the Mac went to sleep."),
        (AwayCause.locked, "when the Mac was locked."),
        (AwayCause.idle, "when the Mac was idle."),
        (AwayCause.onBreak, "when you took a break."),
    ])
    func backNamesTheStoppedActivityByCause(cause: AwayCause, tail: String) {
        let s = Fix.screen(.welcomeBack) {
            $0.away?.cause = cause
            $0.stoppedByAway = "Code review"
        }
        #expect(s.message == "Code review stopped at " + Fix.clock(Fix.at(9, 55)) + " " + tail)
    }

    @Test func backWithNothingRunningBeforeSaysHowLongTheUserWasAway() {
        #expect(Fix.screen(.welcomeBack).message == "You were away 35 min.")
    }

    @Test func backShowsTheAwaySpanAndThePlaces() {
        let s = Fix.screen(.welcomeBack)
        #expect(s.timeText == "AWAY " + Fix.clock(Fix.at(9, 55)) + " – " + Fix.clock(Fix.at(10, 30)))
        #expect(s.showsWhere)
    }

    @Test(arguments: AwayCause.allCases)
    func iWasHereShowsOnlyAfterAnIdleAway(_ cause: AwayCause) {
        let s = Fix.screen(.welcomeBack) { $0.away?.cause = cause }
        #expect(s.showsIWasHere == (cause == .idle))
    }

    @Test func backWithNoLastActivityHasNoKeep() {
        #expect(Fix.screen(.welcomeBack) { $0.lastActivity = nil }.keep == nil)
    }

    @Test func eventShowsItsSpanAndCalendar() {
        let s = Fix.screen(.eventAsk)
        #expect(s.timeText == Fix.clock(Fix.at(12)) + " – " + Fix.clock(Fix.at(13)))
        #expect(s.message == "Design sync is in your Work calendar. It ends by itself at " + Fix.clock(Fix.at(13)) + ".")
    }

    @Test func eventHasAFixedStartNoStartedLinkAndAReadOnlyCalendarNote() {
        let s = Fix.screen(.eventAsk) { $0.switchTimes = [Fix.at(12), Fix.at(12, 5)] }
        #expect(s.fixedStart == Fix.at(12))
        #expect(s.startedChoices.isEmpty)
        #expect(s.calendarNote == "Already in your Work calendar, so Sathi adds no copy.")
    }

    @Test func theCalendarRowLinesUseTheSpecWords() {
        #expect(Copywriter.activityPromptCalendarGoes("Work") == "One event goes to Work when the activity ends.")
        #expect(Copywriter.activityPromptNoEvent == "Sathi adds no event for this activity.")
        #expect(Copywriter.activityPromptCalendarNone == "None")
    }
}
