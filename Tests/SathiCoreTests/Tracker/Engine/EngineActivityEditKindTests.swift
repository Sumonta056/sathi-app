import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine activity edit kind switch")
struct EngineActivityEditKindTests {
    private let work = Activity(
        text: "Spec", category: "Coding", start: wed(9), end: wed(9, 30), calendarID: "work", eventID: "ev9"
    )
    private let away = Activity(kind: .away, text: "Away · Lunch", start: wed(12), end: wed(13), awayPlace: .lunch)

    private func harness(_ items: [Activity]) -> EngineHarness {
        EngineHarness.tracker(at: wed(17), activities: items)
    }

    private func edit(
        _ a: Activity, kind: ActivityKind?, text: String = "Spec", category: String? = "Coding",
        place: AwayPlace? = nil, name: String? = nil, calendar: ActivityCalendarChoice = .keep
    ) -> ActivityEdit {
        ActivityEdit(
            text: text, category: category, start: a.start, end: a.end,
            awayPlace: place, awayPlaceName: name, calendar: calendar, kind: kind
        )
    }

    private func saved(_ h: EngineHarness, _ a: Activity) -> Activity? { h.saved.first { $0.id == a.id } }

    @Test func workToAwayDeletesTheEventAndStoresAnAwayRow() {
        let h = harness([work])
        #expect(h.engine.editActivity(work.id, edit(work, kind: .away, place: .lunch)) == .saved(work.id))
        let row = saved(h, work)
        #expect(row?.kind == .away)
        #expect(row?.awayPlace == .lunch)
        #expect(row?.awayPlaceName == nil)
        #expect(row?.category == nil)
        #expect(row?.calendarID == nil)
        #expect(row?.eventID == nil)
        #expect(row?.text == Copywriter.trackerAwayText(.lunch, name: nil))
        #expect(h.calendarWriter.deleted == ["ev9"])
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func workToAwayWhoseEventCannotBeDeletedSavesNothing() {
        let h = harness([work])
        h.calendarWriter.nextDeleteResult = false
        #expect(h.engine.editActivity(work.id, edit(work, kind: .away, place: .lunch)) == .calendarUnchanged(work.id))
        #expect(saved(h, work) == work)
    }

    @Test func workToAwayKeepsTheNameOfAnOtherPlace() {
        let h = harness([work])
        #expect(h.engine.editActivity(work.id, edit(work, kind: .away, place: .other, name: "Gym hall")) == .saved(work.id))
        #expect(saved(h, work)?.awayPlace == .other)
        #expect(saved(h, work)?.awayPlaceName == "Gym hall")
        #expect(saved(h, work)?.text == Copywriter.trackerAwayText(.other, name: "Gym hall"))
    }

    @Test func workWithoutAnEventToAwayDeletesNothing() {
        var plain = work
        plain.calendarID = nil
        plain.eventID = nil
        let h = harness([plain])
        #expect(h.engine.editActivity(plain.id, edit(plain, kind: .away, place: .walk)) == .saved(plain.id))
        #expect(saved(h, plain)?.kind == .away)
        #expect(saved(h, plain)?.awayPlace == .walk)
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func awayToWorkWithACalendarWritesOneEvent() {
        let h = harness([away])
        let e = edit(away, kind: .work, text: "Sleep", category: "Break", calendar: .calendar("home"))
        #expect(h.engine.editActivity(away.id, e) == .saved(away.id))
        let row = saved(h, away)
        #expect(row?.kind == .work)
        #expect(row?.text == "Sleep")
        #expect(row?.category == "Break")
        #expect(row?.awayPlace == nil)
        #expect(row?.awayPlaceName == nil)
        #expect(row?.calendarID == "home")
        #expect(row?.eventID == "e1")
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.saved.first?.calendarID == "home")
        #expect(h.calendarWriter.saved.first?.title == "Sleep")
    }

    @Test func awayToWorkWithoutACalendarWritesNoEvent() {
        let named = Activity(
            kind: .away, text: "Away · Doctor", start: wed(14), end: wed(15), awayPlace: .other, awayPlaceName: "Doctor"
        )
        let h = harness([named])
        let e = edit(named, kind: .work, text: "Sleep", category: "Break", calendar: .none)
        #expect(h.engine.editActivity(named.id, e) == .saved(named.id))
        #expect(saved(h, named)?.kind == .work)
        #expect(saved(h, named)?.text == "Sleep")
        #expect(saved(h, named)?.awayPlaceName == nil)
        #expect(saved(h, named)?.calendarID == nil)
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test(arguments: [
        Activity(kind: .buddy, text: "Reading", start: wed(10), end: wed(10, 15)),
        Activity(kind: .event, text: "Standup", start: wed(11), end: wed(11, 30), calendarID: "work", sourceEventID: "m1"),
        Activity(text: "Planning", start: wed(11), end: wed(11, 30), calendarID: "work", sourceEventID: "m2")
    ])
    func rowsThatCannotSwitchRefuseAwayAndStayTheSame(_ row: Activity) {
        let h = harness([row])
        #expect(h.engine.editActivity(row.id, edit(row, kind: .away, place: .lunch)) == .notFound)
        #expect(saved(h, row) == row)
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func noKindKeepsAWorkRowAsWork() {
        let h = harness([work])
        let e = edit(work, kind: nil, text: "Spec v2", place: .lunch)
        #expect(h.engine.editActivity(work.id, e) == .saved(work.id))
        let row = saved(h, work)
        #expect(row?.kind == .work)
        #expect(row?.text == "Spec v2")
        #expect(row?.category == "Coding")
        #expect(row?.awayPlace == nil)
        #expect(row?.calendarID == "work")
        #expect(row?.eventID == "ev9")
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func noKindKeepsAnAwayRowAsAway() {
        let h = harness([away])
        #expect(h.engine.editActivity(away.id, edit(away, kind: nil, place: .walk)) == .saved(away.id))
        #expect(saved(h, away)?.kind == .away)
        #expect(saved(h, away)?.awayPlace == .walk)
        #expect(saved(h, away)?.category == nil)
    }
}
