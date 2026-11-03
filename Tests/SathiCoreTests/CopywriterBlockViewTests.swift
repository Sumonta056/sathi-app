import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Time block view copy")
struct CopywriterBlockViewTests {
    private let zone = FixedZone.berlin

    private func shortTime(_ date: Date) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = zone.timeZone
        return date.formatted(style)
    }

    @Test func fixedLines() {
        #expect(Copywriter.blockCardTitle == "Time block")
        #expect(Copywriter.blockStartButton == "Start a time block")
        #expect(Copywriter.blockEyebrow == "NEW TIME BLOCK")
        #expect(Copywriter.blockPrompt == "What are you working on?")
        #expect(Copywriter.blockEndNow == "End now")
        #expect(Copywriter.blockUndo == "Undo")
        #expect(Copywriter.blockOpenSettings == "Open System Settings")
        #expect(Copywriter.blockNoAccess == "Sathi needs calendar access to save your time blocks.")
    }

    @Test(arguments: [
        (TimeBlockLength.open, "Open"), (.minutes(15), "15"), (.minutes(30), "30"), (.minutes(40), "40"),
        (.minutes(45), "45"), (.minutes(60), "1 h"), (.minutes(120), "2 h")
    ])
    func chipLabels(_ length: TimeBlockLength, _ label: String) {
        #expect(Copywriter.blockChipLabel(length) == label)
    }

    @Test func startLabelForAPlannedLengthShowsTheEnd() {
        let end = zone.date(2026, 3, 4, 15, 0)
        #expect(Copywriter.blockStartLabel(end: end, calendar: zone.calendar) == "Start · ends at " + shortTime(end))
    }

    @Test func startLabelForAnOpenBlockIsPlain() {
        #expect(Copywriter.blockStartLabel(end: nil, calendar: zone.calendar) == "Start")
    }

    @Test func progressLine() {
        let end = zone.date(2026, 3, 4, 15, 0)
        let text = Copywriter.blockProgress(elapsed: 18, total: 30, end: end, calendar: zone.calendar)
        #expect(text == "18 of 30 min · ends at " + shortTime(end))
    }

    @Test func sinceLine() {
        let start = zone.date(2026, 3, 4, 14, 30)
        #expect(Copywriter.blockSince(start: start, minutes: 42, calendar: zone.calendar) == "Since " + shortTime(start) + " · 42 min")
    }
}
