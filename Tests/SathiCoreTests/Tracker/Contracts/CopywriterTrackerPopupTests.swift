import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Copywriter tracker popups")
struct CopywriterTrackerPopupTests {
    private let zone = FixedZone.berlin

    @Test func recentDropdownText() {
        #expect(Copywriter.trackerRecent == "Recent")
        #expect(Copywriter.trackerRecentHint == "Pick from your last 10")
        #expect(Copywriter.trackerRecentHeader == "Last 10 · newest first")
    }

    @Test func shortLabels() {
        #expect(Copywriter.trackerOrMore == "Or more")
        #expect(Copywriter.trackerNoCategory == "No category")
        #expect(Copywriter.trackerDonePick == "Done · pick when you switched")
    }

    @Test func untilNamesTheTime() {
        let time = zone.date(2026, 3, 4, 16, 3)
        let clock = Copywriter.trackerClock(time, calendar: zone.calendar)
        #expect(Copywriter.trackerUntil(time, calendar: zone.calendar) == "until " + clock)
    }

    @Test(arguments: [(30, "STILL ON IT? · 30 MIN SO FAR"), (0, "STILL ON IT? · 0 MIN SO FAR"), (95, "STILL ON IT? · 95 MIN SO FAR")])
    func stillOnItEyebrowNamesTheMinutesSoFar(minutes: Int, text: String) {
        #expect(Copywriter.trackerStillSoFarEyebrow(minutes) == text)
    }

    @Test func theLateStillOnItEyebrowKeepsTheAskedTime() {
        let time = zone.date(2026, 3, 4, 10, 30)
        let clock = Copywriter.trackerClock(time, calendar: zone.calendar)
        #expect(Copywriter.trackerStillOnEyebrow(time, late: true, calendar: zone.calendar) == "STILL ON IT? · ASKED " + clock)
    }

    @Test func awayEyebrowHasTheSpanThenTheLength() {
        let start = zone.date(2026, 3, 4, 12, 30)
        let end = zone.date(2026, 3, 4, 13, 15)
        let span = Copywriter.trackerSpan(start, end, calendar: zone.calendar)
        #expect(Copywriter.trackerAwayEyebrow(start, end, calendar: zone.calendar) == "AWAY " + span + " · 45 MIN")
    }

    @Test func awayEyebrowUppercasesHoursToo() {
        let start = zone.date(2026, 3, 4, 12)
        let end = zone.date(2026, 3, 4, 14, 30)
        let span = Copywriter.trackerSpan(start, end, calendar: zone.calendar)
        #expect(Copywriter.trackerAwayEyebrow(start, end, calendar: zone.calendar) == "AWAY " + span + " · 2 H 30 MIN")
    }

    @Test func theNoteFooterNamesTheMinutesUntilItCloses() {
        #expect(Copywriter.trackerNoteCloses == "Logged now · this note closes in 1 min")
    }

    @Test func centerKeysNameTheShortcut() {
        #expect(Copywriter.trackerCenterKeys("⌃⌥⌘Space") == "↵ start · esc close · ⌃⌥⌘Space from anywhere")
        #expect(Copywriter.trackerCenterKeys("⌥⇧K") == "↵ start · esc close · ⌥⇧K from anywhere")
    }

    @Test func centerKeysWithNoShortcutNameOnlyStartAndClose() {
        #expect(Copywriter.trackerCenterKeys(nil) == "↵ start · esc close")
    }

    @Test func welcomeKeys() {
        #expect(Copywriter.trackerWelcomeKeys == "↵ continue · esc keep as Away")
    }
}
