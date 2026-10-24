import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Whole-second times")
struct WholeSecondTests {
    private let fractional = Date(timeIntervalSinceReferenceDate: 792_403_200.734512)
    private let whole = Date(timeIntervalSinceReferenceDate: 792_403_200)

    private func decodeNumeric<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func factoriesDropFractionalSeconds() {
        #expect(HistoryEvent.done(.water, 1, at: fractional).date == whole)
        #expect(HistoryEvent.snooze(.reading, at: fractional).date == whole)
        #expect(HistoryEvent.skip(.water, at: fractional).date == whole)
    }

    @Test func memberwiseInitDropsFractionalSeconds() {
        #expect(HistoryEvent(date: fractional, habit: .water, kind: .done, amount: 1).date == whole)
    }

    @Test func decodedEventDropsFractionalSeconds() throws {
        let json = #"{"date":792403200.734512,"habit":"water","kind":"done","amount":1}"#
        #expect(try decodeNumeric(HistoryEvent.self, json) == .done(.water, 1, at: whole))
    }

    @Test func decodedLiveStateDropsFractionalSeconds() throws {
        let json = #"{"lastWaterDone":792403200.734512,"streakReset":{"water":792320400.5}}"#
        let live = try decodeNumeric(LiveState.self, json)
        #expect(live.lastWaterDone == whole)
        #expect(live.streakReset["water"] == Date(timeIntervalSinceReferenceDate: 792_320_400))
    }
}

@MainActor
@Suite("Engine whole-second times")
struct EngineWholeSecondTests {
    private let start = day(2026, 3, 4, 10).addingTimeInterval(0.734512)

    @Test func loggingWaterStoresWholeSecondTimes() {
        let h = EngineHarness(at: start)
        h.engine.logWater(1)
        #expect(h.engine.data.live.lastWaterDone == day(2026, 3, 4, 10))
        #expect(h.store.live.lastWaterDone == day(2026, 3, 4, 10))
        #expect(h.history.appended.map(\.date) == [day(2026, 3, 4, 10)])
    }

    @Test func emergencySkipStoresWholeSecondTimes() {
        let h = EngineHarness(at: start)
        h.engine.emergencySkip(.water)
        #expect(h.engine.data.live.streakReset[HabitID.water.rawValue] == day(2026, 3, 4, 10))
        #expect(h.store.live.streakReset[HabitID.water.rawValue] == day(2026, 3, 4, 10))
        #expect(h.history.appended.map(\.date) == [day(2026, 3, 4, 10)])
    }
}
