import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoPromptDecoding")
struct TodoPromptDecodingTests {
    private func live(_ json: String) throws -> LiveState {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(LiveState.self, from: Data(json.utf8))
    }

    private func roundTrip(_ l: LiveState) throws -> LiveState {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(LiveState.self, from: e.encode(l))
    }

    private let oldRunning = """
    {"id":"11111111-1111-1111-1111-111111111111","text":"Spec","start":"2026-03-04T10:00:00Z","askAt":"2026-03-04T10:30:00Z"}
    """

    @Test func oldRunningActivityWithoutATodoDecodes() throws {
        let l = try live(#"{"tracker":{"running":\#(oldRunning)}}"#)
        #expect(l.tracker.running?.text == "Spec")
        #expect(l.tracker.running?.todoID == nil)
        #expect(l.tracker.running?.askedTodoDone == false)
    }

    @Test func oldPromptWithoutTodoIDsDecodes() throws {
        let json = #"{"tracker":{"prompt":{"kind":"whatNow","shownAt":"2026-03-04T10:00:00Z","askTime":"2026-03-04T10:00:00Z"}}}"#
        let l = try live(json)
        #expect(l.tracker.prompt?.kind == .whatNow)
        #expect(l.tracker.prompt?.todoIDs == [])
    }

    @Test func badTodoValuesKeepTheRest() throws {
        let bad = oldRunning.dropLast() + #","todoID":42,"askedTodoDone":"yes"}"#
        let json = #"{"tracker":{"running":\#(bad)}}"#
        let l = try live(json)
        #expect(l.tracker.running?.text == "Spec")
        #expect(l.tracker.running?.todoID == nil)
        #expect(l.tracker.running?.askedTodoDone == false)
        let prompt = #"{"tracker":{"prompt":{"kind":"todoDue","shownAt":"2026-03-04T10:00:00Z","askTime":"2026-03-04T10:00:00Z","todoIDs":7}}}"#
        let p = try live(prompt)
        #expect(p.tracker.prompt?.kind == .todoDue)
        #expect(p.tracker.prompt?.todoIDs == [])
    }

    @Test func newFieldsRoundTrip() throws {
        let start = day(2026, 3, 4, 10)
        var l = LiveState()
        var r = RunningActivity(text: "Write report", start: start, expectedLength: .minutes(30), askAt: start.addingTimeInterval(1800))
        r.todoID = "a"
        r.askedTodoDone = true
        l.tracker.running = r
        var p = PromptState(kind: .todoDue, shownAt: start, askTime: start)
        p.todoIDs = ["a", "b"]
        l.tracker.prompt = p
        let back = try roundTrip(l)
        #expect(back.tracker.running?.todoID == "a")
        #expect(back.tracker.running?.askedTodoDone == true)
        #expect(back.tracker.prompt?.kind == .todoDue)
        #expect(back.tracker.prompt?.todoIDs == ["a", "b"])
    }

    @Test func aSavedStateFileWithoutTheFieldsStillLoads() throws {
        let base = makeTempFolder()
        let json = #"{"schemaVersion":1,"value":{"bottleLevel":0.5,"tracker":{"running":\#(oldRunning)}}}"#
        try writeText(json, to: base.appendingPathComponent("state.json"))
        let loaded = FileStateStore(base: base).loadLive()
        #expect(loaded.tracker.running?.text == "Spec")
        #expect(loaded.tracker.running?.todoID == nil)
    }

    @Test func todoDueIsAKnownPromptKindWithTheTodoReason() {
        #expect(PromptKind(rawValue: "todoDue") == .todoDue)
        #expect(PromptReason(.todoDue) == .todo)
    }
}
