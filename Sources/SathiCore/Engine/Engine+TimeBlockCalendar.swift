import Foundation

extension Engine {
    package func calendarChoices() -> [CalendarChoice] { calendarWriter.calendars() }

    package func calendarTitle(_ id: String) -> String? {
        calendarChoices().first { $0.id == id }?.title
    }

    package var startCalendarID: String? {
        let ids = calendarChoices().map(\.id)
        let candidates = [data.prefs.timeBlock.defaultCalendarID, calendarWriter.defaultCalendarID()]
        return candidates.compactMap { $0 }.first(where: ids.contains) ?? ids.first
    }

    package func requestCalendarAccess() async {
        calendarAccess = await calendarWriter.requestAccess()
    }

    package func saveWaitingBlock(to calendarID: String) {
        guard var b = timeBlock, b.waitingForCalendar, let end = b.endedAt else { return }
        b.calendarID = calendarID
        guard write(b, end: end) != nil else { return }
        data.live.timeBlock = nil
        presenter.closeBlockCalendarGone()
        requestTick()
    }

    @discardableResult
    func finish(_ b: TimeBlock, end: Date) -> Bool {
        closeRunningBlock()
        guard write(b, end: end) != nil else {
            wait(b, end: end)
            return false
        }
        data.live.timeBlock = nil
        return true
    }

    func write(_ b: TimeBlock, end: Date) -> String? {
        if let ev = b.savedEventID {
            switch calendarWriter.update(eventID: ev, draft: b.draft(end: end)) {
            case let .saved(id): return id
            case .failed: return nil
            case .calendarMissing: break
            }
        }
        guard case let .saved(id) = calendarWriter.save(b.draft(end: end)) else { return nil }
        return id
    }

    func refreshCalendarAccess() {
        let access = calendarWriter.access
        if calendarAccess != access { calendarAccess = access }
    }

    func wait(_ b: TimeBlock, end: Date) {
        var waiting = b
        waiting.waitingForCalendar = true
        waiting.endedAt = end
        data.live.timeBlock = waiting
        presenter.showBlockCalendarGone()
    }
}
