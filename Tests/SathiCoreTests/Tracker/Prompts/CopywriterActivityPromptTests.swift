import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Copywriter activity prompt")
struct CopywriterActivityPromptTests {
    private typealias Fix = PromptFixture

    @Test func bodyWordsMatchTheSpec() {
        #expect(Copywriter.activityPromptShowAll(8) == "Show all 8")
        #expect(Copywriter.activityPromptField == "Type what you do, or tap a card on the left")
        #expect(Copywriter.activityPromptAddPlace == "+ Place")
        #expect(Copywriter.activityPromptReallyStarted == "It really started at")
        #expect(Copywriter.activityPromptEscSkip == "Esc: Skip")
    }

    @Test func paneAndRowWordsMatchTheSpec() {
        #expect(Copywriter.activityPromptRecentLabel == "RECENT")
        #expect(Copywriter.activityPromptTapToFill == "tap to fill")
        #expect(Copywriter.activityPromptQuiet == "Quiet")
        #expect(Copywriter.activityPromptAllowCalendar == "Allow calendar access")
        #expect(Copywriter.activityPromptKey(1) == "⌘1")
        #expect(Copywriter.activityPromptKey(6) == "⌘6")
    }

    @Test func recentCardDetailNamesTheCategoryAndTheLastLength() {
        #expect(Copywriter.activityPromptRecentDetail(category: "Work", length: 2700) == "Work · last 45 min")
        #expect(Copywriter.activityPromptRecentDetail(category: "Coding Hobby", length: 3600) == "Coding Hobby · last 1 h")
        #expect(Copywriter.activityPromptRecentDetail(category: nil, length: 1800) == "No category · last 30 min")
    }

    @Test func theRecentPaneShowsSixOfTheLastTen() {
        #expect(Limits.recentShown == 6)
        #expect(Limits.recentMax == 10)
    }

    @Test func startedLinkSaysNowOrTheTime() {
        #expect(Copywriter.activityPromptStarted(nil, calendar: Fix.calendar) == "Started: Now · change")
        #expect(Copywriter.activityPromptStarted(Fix.at(10, 15), calendar: Fix.calendar) == "Started: " + Fix.clock(Fix.at(10, 15)) + " · change")
    }

    @Test func eventLengthIsUntilItsEnd() {
        #expect(Copywriter.activityPromptUntil(Fix.at(13), calendar: Fix.calendar) == "Until " + Fix.clock(Fix.at(13)))
    }

    @Test func shortcutTagWithNoShortcutIsYouAsked() {
        let s = Fix.screen(.center) { $0.shortcut = nil }
        #expect(s.tag == "YOU ASKED")
    }
}
