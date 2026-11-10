import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Tracker integration fix round")
struct TrackerFixRoundTests {
    private func tracker(_ json: String) throws -> TrackerPrefs {
        try JSONDecoder().decode(Prefs.self, from: Data(#"{"tracker":\#(json)}"#.utf8)).tracker
    }

    @Test func aSessionThatTimesOutOpensAResumeWhatNowNotByTheUser() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec")
        h.clock.advance(minutes: 10)
        h.engine.startSession(.reading)
        h.advance(minutes: 120)
        #expect(h.engine.trackerPrompt?.resume?.text == "Spec")
        #expect(!h.engine.trackerPromptByUser)
    }

    @Test func aSessionTheUserFinishesOpensAResumeWhatNowByTheUser() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec")
        h.clock.advance(minutes: 10)
        h.engine.startSession(.reading)
        h.clock.advance(minutes: 5)
        h.engine.finishSession(.reading)
        #expect(h.engine.trackerPrompt?.resume?.text == "Spec")
        #expect(h.engine.trackerPromptByUser)
    }

    @Test func doneAndLogActivityAreByTheUserButTheAskTimeIsNot() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.tick()
        #expect(h.promptKind == .whatNow)
        #expect(!h.engine.trackerPromptByUser)
        h.start()
        h.engine.doneActivity()
        #expect(h.engine.trackerPromptByUser)
        h.engine.skipTrackerPrompt()
        #expect(!h.engine.trackerPromptByUser)
        h.engine.openTrackerPanel()
        #expect(h.engine.trackerPromptByUser)
    }

    @Test func theAskedReportDayIsTakenOnce() {
        let h = EngineHarness.tracker(at: wed(10))
        let d = DayKey(wed(10), calendar: .current)
        h.engine.openActivityReport(d)
        #expect(h.engine.takeActivityReportDay() == d)
        #expect(h.engine.takeActivityReportDay() == nil)
        h.engine.openActivityReport(d)
        #expect(h.engine.takeActivityReportDay() == d)
    }

    @Test func aFileWithStartAfterEndRepairsOnlyTheEnd() throws {
        let t = try tracker(#"{"startMinutes":1140,"endMinutes":600}"#)
        #expect(t.startMinutes == 1140)
        #expect(t.endMinutes == 1140 + Limits.scheduleSlotMinutes)
        let late = try tracker(#"{"startMinutes":1440,"endMinutes":1440}"#)
        #expect(late.startMinutes == 1440 - Limits.scheduleSlotMinutes)
        #expect(late.endMinutes == 1440)
    }

    @Test func settingHoursKeepsStartBeforeEnd() {
        var t = TrackerPrefs()
        t.setStart(19 * 60)
        #expect(t.startMinutes == 1140)
        #expect(t.endMinutes == 1140 + Limits.scheduleSlotMinutes)
        t.setEnd(8 * 60)
        #expect(t.endMinutes == 480)
        #expect(t.startMinutes == 480 - Limits.scheduleSlotMinutes)
        t.setEnd(0)
        #expect(t.startMinutes < t.endMinutes)
    }

    @Test func exportNeverOverwritesAFileInTheFolder() throws {
        let item = Activity(text: "Code review", category: "Coding", start: wed(9), end: wed(10))
        let h = EngineHarness.tracker(at: wed(12), activities: [item])
        let folder = makeTempFolder()
        let month = MonthKey(wed(9), calendar: .current)
        let old = folder.appendingPathComponent(ActivityMonthExporter.fileName(month, format: .json))
        try writeText("old", to: old)
        let urls = h.engine.exportActivityMonth(month, to: folder)
        #expect(readText(old) == "old")
        #expect(urls.count == 2)
        #expect(urls.contains { $0.lastPathComponent.hasSuffix(" (2).json") })
        try? FileManager.default.removeItem(at: folder)
    }
}
