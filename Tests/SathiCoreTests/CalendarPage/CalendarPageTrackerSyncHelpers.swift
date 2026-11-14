import Foundation
import SathiCore
import SathiTestSupport

extension EngineHarness {
    static func syncedPage(_ mode: EventMode, opened: Bool = true) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.mirrorsWrites = true
        h.useEvents([], read: ["work"], mode: mode)
        h.start("Spec", minutes: 300)
        if opened { h.engine.calendarPageOpened() }
        return h
    }

    @discardableResult
    func createOnPage(_ title: String = "Design", at slot: Date = wed(14), calendarID: String = "work") -> String {
        var f = engine.calendarPageNewEvent(at: slot)
        f.title = title
        f.calendarID = calendarID
        guard case let .saved(id) = engine.saveCalendarPageEvent(f) else { return "" }
        return id
    }

    var pageDay: CalendarPageData {
        engine.calendarPage(.containing(wed(12), kind: .day, calendar: engine.calendar))
    }

    func pageShowsEvent(_ id: String) -> Bool {
        pageDay.blocks.contains { if case let .event(e) = $0.source { e.id == id } else { false } }
    }

    func blocks(titled title: String) -> [CalendarBlock] {
        pageDay.blocks.filter { $0.title == title }
    }

    func at(_ time: Date) {
        clock.now = time
        engine.tick()
    }

    func reacted(to id: String, _ mode: EventMode) -> Bool {
        switch mode {
        case .askFirst:
            return promptKind == .eventAsk && engine.trackerPrompt?.eventID == id
        case .logAndTell:
            guard case let .event(e) = notes.last else { return false }
            return running?.sourceEventID == id && e.id == id
        }
    }

    var reactedToAny: Bool {
        promptKind == .eventAsk || running?.sourceEventID != nil || !notes.isEmpty
    }
}
