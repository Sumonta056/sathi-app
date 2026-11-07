import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("LiveState session decoding")
struct LiveStateSessionDecodingTests {
    private func live(_ json: String) throws -> LiveState {
        try JSONDecoder().decode(LiveState.self, from: Data(json.utf8))
    }

    private func json(_ value: some Encodable) throws -> String {
        try String(bytes: JSONEncoder().encode(value), encoding: .utf8) ?? ""
    }

    @Test func oldStateWithoutKeyLoadsNil() throws {
        let s = try live(#"{"bottleLevel":0.5}"#)
        #expect(s.meditationSession == nil)
        #expect(s.bottleLevel == 0.5)
    }

    @Test func malformedSessionLoadsNilAndKeepsTheRest() throws {
        let block = TimeBlock(title: "Plan", startedAt: day(2026, 3, 4, 9), length: .minutes(30), calendarID: "work")
        let blockJSON = try json(block)
        let s = try live(#"{"bottleLevel":0.4,"quickReminders":[],"timeBlock":\#(blockJSON),"meditationSession":"oops"}"#)
        #expect(s.meditationSession == nil)
        #expect(s.bottleLevel == 0.4)
        #expect(s.quickReminders.isEmpty)
        #expect(s.timeBlock == block)
    }

    @Test func sessionWithoutEndLoadsNil() throws {
        let s = try live(#"{"meditationSession":{"start":792403200}}"#)
        #expect(s.meditationSession == nil)
    }

    @Test func roundTripKeepsPausedAt() throws {
        var state = LiveState()
        let begin = day(2026, 3, 4, 10)
        state.meditationSession = Session(
            start: begin, end: begin.addingTimeInterval(600), pausedAt: begin.addingTimeInterval(90), fromReminder: true
        )
        let back = try JSONDecoder().decode(LiveState.self, from: JSONEncoder().encode(state))
        #expect(back.meditationSession == state.meditationSession)
        #expect(back.meditationSession?.pausedAt == begin.addingTimeInterval(90))
    }

    @Test func missingFromReminderDefaultsFalse() throws {
        let s = try live(#"{"meditationSession":{"start":792403200,"end":792403800}}"#)
        #expect(s.meditationSession?.fromReminder == false)
        #expect(s.meditationSession?.pausedAt == nil)
    }
}
