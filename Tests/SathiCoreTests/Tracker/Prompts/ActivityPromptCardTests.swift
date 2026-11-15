import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Activity prompt running card")
struct ActivityPromptCardTests {
    private typealias Fix = PromptFixture

    private func started(_ date: Date = Fix.at(10)) -> String { "Started " + Fix.clock(date) }

    @Test(arguments: PromptKind.allCases)
    func aCardShowsExactlyWhenThereIsAKeepAction(_ kind: PromptKind) {
        let s = Fix.screen(kind) {
            $0.resume = ActivityDraft(text: "Spec")
            $0.running = Fix.running()
        }
        #expect((s.card != nil) == (s.keep != nil))
    }

    @Test func endsCardShowsTheRunningActivityAndItsProgress() throws {
        let s = Fix.screen(.stillOnIt, now: Fix.at(10, 20))
        let card = try #require(s.card)
        #expect(card.tag == "NOW RUNNING")
        #expect(card.text == "Code review")
        #expect(card.category == "Coding")
        #expect(card.detail == started() + " · 20 of 30 min")
        let progress = try #require(card.progress)
        #expect(abs(progress - 2.0 / 3.0) < 0.0001)
    }

    @Test func endsTitleAndMessageAreShortWithACard() {
        let s = Fix.screen(.stillOnIt, now: Fix.at(10, 20))
        #expect(s.title == "Still on Code review?")
        #expect(s.message == "20 min so far. Keep going, or switch.")
    }

    @Test func progressStopsAtFullPastTheLength() {
        let s = Fix.screen(.stillOnIt, now: Fix.at(10, 42))
        #expect(s.card?.progress == 1)
        #expect(s.card?.detail == started() + " · 42 min · 12 min over")
    }

    @Test func anOpenActivityHasNoProgressAndCountsSoFar() {
        let s = Fix.screen(.stillOnIt, now: Fix.at(11)) { $0.running = Fix.running(length: .open) }
        #expect(s.card?.progress == nil)
        #expect(s.card?.detail == started() + " · 60 min so far")
        #expect(s.card?.tag == "NOW RUNNING")
    }

    @Test func lateEndsKeepsTheWaitedMessageAndTheCard() {
        let s = Fix.screen(.stillOnIt) { $0.waitedMinutes = 7 }
        #expect(s.message == "This question waited 7 min.")
        #expect(s.title == "Still on Code review?")
        #expect(s.card?.text == "Code review")
    }

    @Test func endsWithNothingRunningHasNoCard() {
        #expect(Fix.screen(.stillOnIt) { $0.running = nil }.card == nil)
    }

    @Test func shortcutWhileRunningShowsTheRunningCard() throws {
        let s = Fix.screen(.center, now: Fix.at(10, 15)) { $0.running = Fix.running() }
        let card = try #require(s.card)
        #expect(card.tag == "NOW RUNNING")
        #expect(card.text == "Code review")
        #expect(card.category == "Coding")
        #expect(card.detail == started() + " · 15 of 30 min")
        #expect(card.progress == 0.5)
        #expect(s.title == "Switch to something new?")
        #expect(s.message == "Keep it, or type a new one to switch.")
    }

    @Test func shortcutWithNothingRunningHasNoCard() {
        let s = Fix.screen(.center)
        #expect(s.card == nil)
        #expect(s.message == "Nothing is running.")
    }

    @Test func backCardShowsTheActivityBeforeTheAway() throws {
        let s = Fix.screen(.welcomeBack) {
            $0.lastActivity = ActivityDraft(text: "Code review", category: "Coding")
            $0.stoppedByAway = "Code review"
        }
        let card = try #require(s.card)
        #expect(card.tag == "BEFORE YOU LEFT")
        #expect(card.text == "Code review")
        #expect(card.category == "Coding")
        #expect(card.detail == "Code review stopped at " + Fix.clock(Fix.at(9, 55)) + " when the Mac went to sleep.")
        #expect(card.progress == nil)
        #expect(s.title == "Welcome back. Where were you?")
        #expect(s.message == "You were away 35 min.")
    }

    @Test func backWithNoStoppedActivityDoesNotRepeatTheHeaderInTheCard() {
        let s = Fix.screen(.welcomeBack)
        #expect(s.card?.detail == "")
        #expect(s.message == "You were away 35 min.")
    }

    @Test func backWithNoLastActivityHasNoCard() {
        let s = Fix.screen(.welcomeBack) { $0.lastActivity = nil }
        #expect(s.card == nil)
        #expect(s.message == "You were away 35 min.")
    }

    @Test func askAfterABuddySessionShowsTheLastActivity() throws {
        let s = Fix.screen(.whatNow) {
            $0.resume = ActivityDraft(text: "Spec", category: "Writing")
            $0.lastEnded = Activity(kind: .buddy, text: "Reading", start: Fix.at(10), end: Fix.at(10, 25))
        }
        let card = try #require(s.card)
        #expect(card.tag == "LAST ACTIVITY")
        #expect(card.text == "Spec")
        #expect(card.category == "Writing")
        #expect(card.detail == "Reading ended at " + Fix.clock(Fix.at(10, 25)) + ".")
        #expect(card.progress == nil)
        #expect(s.message == "Continue it, or start something new.")
        #expect(s.title == "What are you doing now?")
    }

    @Test func askWithResumeButNoLastEndHasAnEmptyDetail() {
        let s = Fix.screen(.whatNow) { $0.resume = ActivityDraft(text: "Spec") }
        #expect(s.card?.text == "Spec")
        #expect(s.card?.detail == "")
    }

    @Test func askWithNothingToContinueHasNoCardAndKeepsItsMessage() {
        let s = Fix.screen(.whatNow) { $0.lastEnded = Activity(text: "Standup", start: Fix.at(10), end: Fix.at(10, 20)) }
        #expect(s.card == nil)
        #expect(s.message == "Nothing is running. Standup ended at " + Fix.clock(Fix.at(10, 20)) + ".")
    }

    @Test func anEventNeverHasACard() {
        let s = Fix.screen(.eventAsk) { $0.running = Fix.running() }
        #expect(s.card == nil)
    }
}
