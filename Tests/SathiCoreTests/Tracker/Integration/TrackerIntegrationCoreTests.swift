import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Tracker integration core")
struct TrackerIntegrationCoreTests {
    private func tracker(_ json: String) throws -> TrackerPrefs {
        try JSONDecoder().decode(Prefs.self, from: Data(#"{"tracker":\#(json)}"#.utf8)).tracker
    }

    @Test func stillOnItStateCarriesTheUsersAskEvery() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 20 }
        h.start(minutes: 30)
        h.advance(minutes: 30)
        #expect(h.promptKind == .stillOnIt)
        #expect(h.engine.trackerPromptState(.stillOnIt)?.askEveryMinutes == 20)
    }

    @Test func menuBarShowsQuietUntilDuringQuietTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30, quiet: true)
        h.engine.tick()
        #expect(h.engine.statusText == Copywriter.trackerQuietUntilMenu(wed(10, 30), calendar: .current))
        h.engine.endQuietTime()
        #expect(h.engine.statusText != Copywriter.trackerQuietUntilMenu(wed(10, 30), calendar: .current))
    }

    @Test func aUsualLengthThatIsNoChipLoadsTheDefault() throws {
        #expect(try tracker(#"{"usualLength":7}"#).usualLength == TrackerPrefs().usualLength)
        #expect(try tracker(#"{"usualLength":60}"#).usualLength == .minutes(60))
        #expect(try tracker(#"{"usualLength":"open"}"#).usualLength == .open)
    }

    @Test func eventAskCopySaysYesAndNoteLengthComesFromTiming() {
        #expect(Copywriter.trackerYesLogIt == "Yes")
        let line = Copywriter.trackerEventEnded("Standup", at: wed(10), calendar: .current)
        #expect(line.hasSuffix("closes in \(Int(Timing.eventNoteShow / Timing.minute)) min."))
    }
}
