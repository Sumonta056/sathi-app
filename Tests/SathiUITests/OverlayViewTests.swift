import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Lock, session and celebration")
struct OverlayViewTests {
    @Test func lockShowsTheWaterMessage() throws {
        let h = EngineHarness()
        let sut = LockView(id: .water).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "Fota is drying up. Go get some water.") != nil)
        #expect(try sut.inspect().find(text: "Press and hold.") != nil)
    }

    @Test func lockOffersAnEmergencySkip() throws {
        let h = EngineHarness()
        let sut = LockSkipArea(id: .water).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "Emergency skip") != nil)
    }

    @Test func sessionShowsTheTimerAndStopsEarly() throws {
        let h = EngineHarness()
        h.engine.startReading()
        let sut = SessionView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "READING · DO NOT DISTURB") != nil)
        try sut.inspect().find(button: "Stop early (won't count)").tap()
        #expect(h.engine.phase == .idle)
    }

    @Test func sessionMentionsQueuedWater() throws {
        let h = EngineHarness(at: day(2026, 3, 4, 11, 50)) { $0.live.lastWaterDone = day(2026, 3, 4, 10) }
        h.engine.startReading()
        h.advance(minutes: 11)
        let sut = SessionView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "Fota is waiting for you after this") != nil)
    }

    @Test func celebrationShowsTheAmountAndCloses() throws {
        let h = EngineHarness()
        h.engine.logWater(1)
        let sut = CelebrateView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "+1 glass") != nil)
        #expect(try sut.inspect().find(text: h.engine.celebration.title) != nil)
        try sut.inspect().find(button: "Back to work").tap()
        #expect(h.engine.phase == .idle)
    }

    @Test func readingCelebrationShowsTheWeek() throws {
        let h = EngineHarness()
        h.engine.startReading()
        h.advance(minutes: 15)
        let sut = CelebrateView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "15 min read") != nil)
        #expect(try sut.inspect().find(ReadingWeekRow.self) != nil)
    }

    @Test(arguments: [(0, 1, [0]), (3, 2, [2, 3]), (6, 7, [0, 1, 2, 3, 4, 5, 6]), (2, 0, [Int]())])
    func weekRowLightsTheStreakDays(_ weekday: Int, _ streak: Int, _ lit: [Int]) {
        let actual = (0 ..< 7).filter { ReadingWeekRow.isLit($0, weekday: weekday, streak: streak) }
        #expect(actual == lit)
    }

    @Test func mondayIndexStartsTheWeekOnMonday() {
        #expect(ReadingWeekRow.mondayIndex(of: day(2026, 3, 2, 12)) == 0)
        #expect(ReadingWeekRow.mondayIndex(of: day(2026, 3, 8, 12)) == 6)
    }
}
