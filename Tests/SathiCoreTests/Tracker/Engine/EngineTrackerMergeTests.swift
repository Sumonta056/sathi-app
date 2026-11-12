import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine same activity answered again")
struct EngineTrackerMergeTests {
    private func draft(_ text: String = "Gaming", _ category: String? = "Break", calendar: String? = nil) -> ActivityDraft {
        ActivityDraft(text: text, category: category, length: .minutes(30), calendarID: calendar)
    }

    private func answer(_ h: EngineHarness, _ d: ActivityDraft, after minutes: Double = 10) {
        h.engine.startActivity(d)
        h.advance(minutes: minutes)
    }

    @Test func sameTextAndCategoryKeepOneRow() {
        let h = EngineHarness.tracker(at: wed(10))
        for _ in 0 ..< 3 {
            answer(h, draft())
        }
        h.engine.startActivity(draft("Mail", "Work"))
        #expect(h.saved.count == 1)
        #expect(h.saved[0].text == "Gaming")
        #expect(h.saved[0].start == wed(10))
        #expect(h.saved[0].end == wed(10, 30))
    }

    @Test func differentCategoryKeepsTwoRows() {
        let h = EngineHarness.tracker(at: wed(10))
        answer(h, draft())
        answer(h, draft("Gaming", "Coding"))
        h.engine.startActivity(draft("Mail", "Work"))
        #expect(h.saved.map(\.category) == ["Break", "Coding"])
    }

    @Test func differentTextKeepsTwoRows() {
        let h = EngineHarness.tracker(at: wed(10))
        answer(h, draft())
        answer(h, draft("Chess"))
        h.engine.startActivity(draft("Mail", "Work"))
        #expect(h.saved.map(\.text) == ["Gaming", "Chess"])
    }

    @Test func gapOfTwoMinutesKeepsTwoRows() {
        let first = Activity(text: "Gaming", category: "Break", start: wed(9, 48), end: wed(9, 58))
        let h = EngineHarness.tracker(at: wed(10), activities: [first])
        answer(h, draft())
        h.engine.startActivity(draft("Mail", "Work"))
        #expect(h.saved.count == 2)
    }

    @Test func awayRowBetweenKeepsTwoRows() {
        let first = Activity(text: "Gaming", category: "Break", start: wed(9, 40), end: wed(9, 50))
        let away = Activity(kind: .away, text: "Away", start: wed(9, 50), end: wed(10))
        let h = EngineHarness.tracker(at: wed(10), activities: [first, away])
        answer(h, draft())
        h.engine.startActivity(draft("Mail", "Work"))
        #expect(h.saved.map(\.kind) == [.work, .away, .work])
    }

    @Test func mergedRowUpdatesItsOneCalendarEvent() {
        let h = EngineHarness.tracker(at: wed(10))
        answer(h, draft(calendar: "work"))
        h.engine.startActivity(draft(calendar: "work"))
        h.advance(minutes: 10)
        h.engine.startActivity(draft("Mail", "Work"))
        #expect(h.saved.count == 1)
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.updated.last?.1.end == wed(10, 20))
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.saved[0].eventID != nil)
    }

    @Test func oldRowWithEventAbsorbsNewRowWithoutEvent() {
        let first = Activity(text: "Gaming", category: "Break", start: wed(9, 50), end: wed(10), calendarID: "work", eventID: "e1")
        let h = EngineHarness.tracker(at: wed(10), activities: [first])
        answer(h, draft())
        h.engine.startActivity(draft("Mail", "Work"))
        #expect(h.saved.count == 1)
        #expect(h.saved[0].eventID == "e1")
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.calendarWriter.updated.first?.1.end == wed(10, 10))
    }
}
