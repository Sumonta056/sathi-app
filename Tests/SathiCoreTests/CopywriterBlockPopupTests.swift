import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Time block popup copy")
struct CopywriterBlockPopupTests {
    private let zone = FixedZone.berlin

    private func shortTime(_ date: Date) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = zone.timeZone
        return date.formatted(style)
    }

    @Test func fixedLines() {
        #expect(Copywriter.blockEndAndSave == "End and save")
        #expect(Copywriter.blockDoneEyebrow == "TIME BLOCK · DONE")
        #expect(Copywriter.blockDone == "Done")
        #expect(Copywriter.blockExtendLabel == "+15 min")
        #expect(Copywriter.blockCheckInEyebrow == "TIME BLOCK · 2 HOURS")
        #expect(Copywriter.blockKeepGoing == "Keep going")
        #expect(Copywriter.blockGoneEyebrow == "TIME BLOCK · NOT SAVED YET")
        #expect(Copywriter.blockYourCalendar == "your calendar")
    }

    @Test(arguments: [(30, "30 min on Plan"), (60, "1 h on Plan"), (75, "75 min on Plan")])
    func doneSummary(_ minutes: Int, _ text: String) {
        #expect(Copywriter.blockDoneSummary(minutes: minutes, title: "Plan") == text)
    }

    @Test func savedLineShowsCalendarAndTimes() {
        let start = zone.date(2026, 3, 4, 14, 30)
        let end = zone.date(2026, 3, 4, 15, 0)
        let text = Copywriter.blockSavedTo("Work", start: start, end: end, calendar: zone.calendar)
        #expect(text == "Saved to Work · " + shortTime(start) + " – " + shortTime(end))
    }

    @Test func checkInStartedLine() {
        let start = zone.date(2026, 3, 4, 14, 30)
        let text = Copywriter.blockStartedAt(start, calendar: zone.calendar)
        #expect(text == "Started at " + shortTime(start) + ". Sathi asks again in 2 hours.")
    }

    @Test func goneHeadlineWithAndWithoutAName() {
        #expect(Copywriter.blockCalendarGone("Work") == "Your calendar “Work” is gone")
        #expect(Copywriter.blockCalendarGone(nil) == "Your calendar is gone")
    }

    @Test func failedHeadline() {
        #expect(Copywriter.blockSaveFailed("Work") == "Sathi could not save to “Work”")
    }

    @Test func chooseLine() {
        #expect(Copywriter.blockChooseCalendar(minutes: 5, title: "Plan") == "Choose one to save 5 min on Plan.")
    }

    @Test func widgetHintForAPlannedBlockShowsTheEnd() {
        let start = zone.date(2026, 3, 4, 14, 30)
        let end = zone.date(2026, 3, 4, 15, 0)
        let text = Copywriter.blockWidgetHint(end: end, start: start, calendarTitle: "Work", calendar: zone.calendar)
        #expect(text == "ends " + shortTime(end) + " · Work")
    }

    @Test func widgetHintForAnOpenBlockShowsTheStart() {
        let start = zone.date(2026, 3, 4, 14, 30)
        let text = Copywriter.blockWidgetHint(end: nil, start: start, calendarTitle: "Work", calendar: zone.calendar)
        #expect(text == "since " + shortTime(start) + " · Work")
    }
}
