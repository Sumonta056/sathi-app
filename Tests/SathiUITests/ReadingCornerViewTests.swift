import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reading corner views")
struct ReadingCornerViewTests {
    private func harness(_ style: ReadingReminderStyle) -> EngineHarness {
        EngineHarness {
            $0.prefs.reading.reminderStyle = style
            $0.prefs.reading.sessionMinutes = 15
            $0.prefs.general.snoozeMinutes = 5
        }
    }

    private func finishedSession(_ style: ReadingReminderStyle) -> EngineHarness {
        let h = harness(style)
        h.engine.startReading()
        h.advance(minutes: 15)
        return h
    }

    private func celebrate(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try CelebrateView().environmentObject(h.engine).inspect()
    }

    @Test func timerPillShowsTheCompanionAndStops() throws {
        let h = harness(.corner)
        h.showReminder(.reading)
        h.engine.startReading()
        let sut = try ReadingTimerPill().environmentObject(h.engine).inspect()
        #expect(try sut.find(text: "Boi is reading with you") != nil)
        try Find.button(sut, holding: "Stop").tap()
        #expect(h.engine.activities.isEmpty)
        #expect(!h.engine.data.events.contains { $0.habit == .reading && $0.kind == .done })
    }

    @Test func cornerCelebrationShowsTheDoneCard() throws {
        let h = finishedSession(.corner)
        #expect(h.engine.isCelebrating)
        let sut = try celebrate(h)
        #expect(try sut.find(ReadingDoneCard.self) != nil)
        #expect(try sut.find(text: "Lovely, 15 minutes read") != nil)
        #expect(try sut.find(text: "A good start.") != nil)
        #expect((try? sut.find(LegacyCelebrate.self)) == nil)
    }

    @Test func doneCardCloseEndsTheCelebration() throws {
        let h = finishedSession(.corner)
        try Find.button(celebrate(h), label: "Close").tap()
        #expect(!h.engine.isCelebrating)
    }

    @Test func doneCardHintCountsTheStreak() throws {
        let h = EngineHarness {
            $0.prefs.reading.reminderStyle = .corner
            $0.prefs.reading.sessionMinutes = 15
            $0.events = [.done(.reading, 15, at: day(2026, 3, 3, 22, 15))]
        }
        h.engine.startReading()
        h.advance(minutes: 15)
        #expect(try celebrate(h).find(text: "That is 2 days in a row.") != nil)
    }

    @Test func focusCelebrationKeepsTheLegacyCard() throws {
        let h = finishedSession(.focus)
        let sut = try celebrate(h)
        #expect(try sut.find(LegacyCelebrate.self) != nil)
        #expect(try sut.find(text: "15 min read") != nil)
        #expect(try sut.find(ReadingWeekRow.self) != nil)
        #expect((try? sut.find(ReadingDoneCard.self)) == nil)
    }

    @Test func snoozedNoteShowsWhenBoiComesBack() throws {
        let h = harness(.corner)
        let until = day(2026, 3, 4, 22, 10)
        let sut = try SnoozedNote(id: .reading, until: until).environmentObject(h.engine).inspect()
        #expect(try sut.find(text: h.engine.comesBackText(.reading, until: until)) != nil)
        #expect(try sut.find(text: "Boi comes back at " + until.formatted(date: .omitted, time: .shortened)) != nil)
    }
}
