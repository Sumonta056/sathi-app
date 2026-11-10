import Foundation
import SathiCore
import Testing

@Suite("Copywriter tracker")
struct CopywriterTrackerTests {
    @Test(arguments: [
        (45 * 60.0, "45 min"),
        (60 * 60.0, "1 h"),
        (150 * 60.0, "2 h 30 min"),
        (59.0, "0 min")
    ])
    func durationReadsInHoursAndMinutes(seconds: TimeInterval, text: String) {
        #expect(Copywriter.trackerDuration(seconds) == text)
    }

    @Test(arguments: [
        (425 * 60.0, "7 h 05"),
        (45 * 60.0, "45 min"),
        (120 * 60.0, "2 h 00")
    ])
    func tileDurationPadsMinutes(seconds: TimeInterval, text: String) {
        #expect(Copywriter.trackerTileDuration(seconds) == text)
    }

    @Test func lengthLabels() {
        #expect(Copywriter.trackerLengthLabel(.minutes(15)) == "15 min")
        #expect(Copywriter.trackerLengthLabel(.minutes(60)) == "1 h")
        #expect(Copywriter.trackerLengthLabel(.open) == "Open")
    }

    @Test func askOffsetLabels() {
        #expect(Copywriter.trackerAskOffsetLabel(0) == "When it ends")
        #expect(Copywriter.trackerAskOffsetLabel(5) == "5 min after")
        #expect(Copywriter.trackerAskOffsetLabel(15) == "15 min after")
    }

    @Test(arguments: [(0, "When it ends"), (5, "+5 min"), (15, "+15 min")])
    func shortAskOffsetLabels(minutes: Int, text: String) {
        #expect(Copywriter.trackerAskOffsetShort(minutes) == text)
    }

    @Test func promptLines() {
        #expect(Copywriter.trackerYesMore(15) == "Yes, 15 min more")
        #expect(Copywriter.trackerWaited(50) == "This question waited 50 min.")
        #expect(Copywriter.trackerContinue("Client work") == "Continue Client work")
        #expect(Copywriter.trackerEventAsk("Client meeting") == "Client meeting started. Log it?")
        #expect(Copywriter.trackerAlsoNow("Retro") == "Also now: Retro")
    }

    @Test func shortcutReadsInMacOrder() {
        let s = KeyShortcut(keyCode: 49, modifiers: [.command, .option], keyName: "Space")
        #expect(Copywriter.trackerShortcut(s) == "⌥⌘Space")
        let all = KeyShortcut(keyCode: 40, modifiers: Set(KeyModifier.allCases), keyName: "K")
        #expect(Copywriter.trackerShortcut(all) == "⌃⌥⇧⌘K")
        #expect(Copywriter.trackerShortcut(.trackerDefault) == "⌃⌥⌘Space")
    }

    @Test func standupAndMonthLines() {
        #expect(Copywriter.trackerStandupLine(text: "Client work", category: "Coding", length: 9000) == "• Client work (Coding) · 2 h 30 min")
        #expect(Copywriter.trackerStandupLine(text: "Lunch walk", category: nil, length: 1800) == "• Lunch walk · 30 min")
        #expect(Copywriter.trackerMonthCategoryLine(category: "Coding", length: 3600, percent: 42) == "Coding · 1 h (42%)")
        #expect(Copywriter.trackerMonthAverage(5400) == "Average 1 h 30 min a day")
    }

    @Test func awayTextNamesThePlace() {
        #expect(Copywriter.trackerAwayText(nil) == "Away")
        #expect(Copywriter.trackerAwayText(.lunch) == "Away · Lunch")
        #expect(Copywriter.trackerAwayText(.breakTime) == "Away · Break")
    }
}
