import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Quick reminder decoding")
struct QuickReminderDecodingTests {
    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private func live(_ json: String) throws -> LiveState {
        try decoder().decode(LiveState.self, from: Data(json.utf8))
    }

    private func item(_ text: String, due: String = "2026-03-04T10:00:00Z", n: Int = 0) -> String {
        #"{"id":"\#(UUID().uuidString)","text":"\#(text)","due":"\#(due)","createdAt":"2026-03-04T09:00:00Z","snoozes":\#(n)}"#
    }

    private func stamp(_ minute: Int) -> String {
        String(format: "2026-03-04T10:%02d:00Z", minute)
    }

    @Test func oldStateWithoutKeyLoadsEmpty() throws {
        let s = try live(#"{"bottleLevel":0.5}"#)
        #expect(s.quickReminders == [])
        #expect(s.bottleLevel == 0.5)
    }

    @Test func decodeDropsBadKeepsGood() throws {
        let bad = #"{"id":"\#(UUID().uuidString)","text":"x","due":"nope","createdAt":"2026-03-04T09:00:00Z"}"#
        let json = #"{"bottleLevel":0.4,"lastDaySummary":"2026-03-03","quickReminders":[\#(item("Call mom")),\#(item("  ")),\#(bad)]}"#
        let s = try live(json)
        #expect(s.quickReminders.map(\.text) == ["Call mom"])
        #expect(s.bottleLevel == 0.4)
        #expect(s.lastDaySummary != nil)
    }

    @Test func aNonListKeepsTheOtherLiveState() throws {
        let s = try live(#"{"bottleLevel":0.4,"quickReminders":"oops"}"#)
        #expect(s.quickReminders == [])
        #expect(s.bottleLevel == 0.4)
    }

    @Test func decodeKeepsEarliestTwenty() throws {
        let items = (0 ..< 25).reversed().map { item("n\($0)", due: stamp($0)) }.joined(separator: ",")
        let s = try live(#"{"quickReminders":[\#(items)]}"#)
        #expect(s.quickReminders.count == Limits.quickMax)
        #expect(s.quickReminders.map(\.text) == (0 ..< 20).map { "n\($0)" })
    }

    @Test func snoozedUntilDecidesTheOrder() throws {
        let id = UUID().uuidString
        let a = #"{"id":"\#(id)","text":"late","due":"\#(stamp(1))","createdAt":"\#(stamp(0))","#
            + #""snoozedUntil":"\#(stamp(30))","snoozes":1}"#
        let s = try live(#"{"quickReminders":[\#(a),\#(item("early", due: stamp(10)))]}"#)
        #expect(s.quickReminders.map(\.text) == ["early", "late"])
    }

    @Test func equalTimesOrderById() throws {
        let low = "00000000-0000-0000-0000-000000000001"
        let high = "00000000-0000-0000-0000-000000000002"
        func raw(_ id: String, _ text: String) -> String {
            #"{"id":"\#(id)","text":"\#(text)","due":"\#(stamp(5))","createdAt":"\#(stamp(0))","snoozes":0}"#
        }
        let s = try live(#"{"quickReminders":[\#(raw(high, "b")),\#(raw(low, "a"))]}"#)
        #expect(s.quickReminders.map(\.text) == ["a", "b"])
    }

    @Test func duplicateIdKeepsOne() throws {
        let id = UUID().uuidString
        func raw(_ text: String) -> String {
            #"{"id":"\#(id)","text":"\#(text)","due":"\#(stamp(5))","createdAt":"\#(stamp(0))","snoozes":0}"#
        }
        let s = try live(#"{"quickReminders":[\#(raw("first")),\#(raw("second"))]}"#)
        #expect(s.quickReminders.count == 1)
    }

    @Test func decodeCutsLongText() throws {
        let s = try live(#"{"quickReminders":[\#(item(String(repeating: "a", count: 100)))]}"#)
        #expect(s.quickReminders.first?.text.count == Limits.quickTextMax)
    }

    @Test func decodeCleansLineBreaks() throws {
        let s = try live(#"{"quickReminders":[\#(item("  Call\\nmom "))]}"#)
        #expect(s.quickReminders.first?.text == "Call mom")
    }

    @Test func aMissingSnoozeCountIsZero() throws {
        let json = #"{"id":"\#(UUID().uuidString)","text":"x","due":"\#(stamp(1))","createdAt":"\#(stamp(0))"}"#
        let s = try live(#"{"quickReminders":[\#(json)]}"#)
        #expect(s.quickReminders.first?.snoozes == 0)
        #expect(s.quickReminders.first?.snoozedUntil == nil)
    }

    @Test func decodeRoundsDatesToWholeSeconds() throws {
        let json = #"{"id":"\#(UUID().uuidString)","text":"x","due":"2026-03-04T10:00:00.700Z","createdAt":"2026-03-04T09:00:00Z"}"#
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let raw = try dec.singleValueContainer().decode(String.self)
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.date(from: raw) ?? Date()
        }
        let r = try d.decode(QuickReminder.self, from: Data(json.utf8))
        #expect(r.due == r.due.wholeSecond)
    }

    @Test func quickReminderRoundTrips() throws {
        var r = QuickReminder(text: "Call mom", due: day(2026, 3, 4, 10), createdAt: day(2026, 3, 4, 9))
        r.snoozes = 2
        r.snoozedUntil = day(2026, 3, 4, 10, 5)
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        let back = try decoder().decode(QuickReminder.self, from: e.encode(r))
        #expect(back == r)
        #expect(back.fireDate == day(2026, 3, 4, 10, 5))
    }

    @Test func newReminderStartsUnsnoozed() {
        let r = QuickReminder(text: "x", due: day(2026, 3, 4, 10), createdAt: day(2026, 3, 4, 9))
        #expect(r.snoozes == 0)
        #expect(r.snoozedUntil == nil)
        #expect(r.fireDate == r.due)
    }
}
