import Foundation

extension Engine {
    package func calendarChoices() -> [CalendarChoice] {
        if let cached = calendarChoicesCache { return cached }
        let fresh = calendarWriter.calendars()
        calendarChoicesCache = fresh
        return fresh
    }

    func refreshCalendarChoices() {
        let fresh = calendarWriter.calendars()
        guard fresh != calendarChoicesCache else { return }
        objectWillChange.send()
        calendarChoicesCache = fresh
    }

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
        refreshCalendarChoices()
    }

    package func saveWaitingBlock(to calendarID: String) {
        guard var b = timeBlock, b.waitingForCalendar, let end = b.endedAt else { return }
        b.calendarID = calendarID
        guard write(b, end: end) != nil else {
            refreshCalendarChoices()
            presenter.showBlockCalendarGone()
            return
        }
        data.live.timeBlock = nil
        waitingCalendarPick = nil
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
        if let ev = b.savedEventID, !ev.isEmpty {
            switch calendarWriter.update(eventID: ev, draft: b.draft(end: end)) {
            case let .saved(id): return id
            case .failed: return nil
            case .calendarMissing: break
            }
        }
        guard case let .saved(id) = calendarWriter.save(b.draft(end: end)) else { return nil }
        return id
    }

    package func refreshCalendarAccess() {
        readCalendarAccess()
        refreshCalendarChoices()
    }

    func refreshCalendarAccessIfDue() {
        if let last = lastAccessRefresh, clock.now.timeIntervalSince(last) < Timing.minute { return }
        if readCalendarAccess() { refreshCalendarChoices() }
    }

    @discardableResult
    private func readCalendarAccess() -> Bool {
        lastAccessRefresh = clock.now
        let access = calendarWriter.access
        guard calendarAccess != access else { return false }
        calendarAccess = access
        return true
    }

    func wait(_ b: TimeBlock, end: Date) {
        var waiting = b
        waiting.waitingForCalendar = true
        waiting.endedAt = end
        data.live.timeBlock = waiting
        waitingCalendarPick = nil
        refreshCalendarChoices()
        presenter.showBlockCalendarGone()
    }
}
