import Foundation

extension Engine {
    package var readingPick: ReadingItem? { data.prefs.reading.list.pick }

    package var readingSessionItem: ReadingItem? { session(.reading).flatMap(unreadItem) }

    func unreadItem(_ s: Session) -> ReadingItem? {
        guard let id = s.readingItem else { return nil }
        return data.prefs.reading.list.first { $0.id == id && $0.doneOn == nil }
    }

    @discardableResult
    package func addReading(url: String, title: String) -> ReadingAddResult {
        let outcome = data.prefs.reading.list.adding(url: url, title: title, on: today)
        setReadingList(outcome.list)
        return outcome.result
    }

    package func removeReading(id: UUID) {
        setReadingList(data.prefs.reading.list.removing(id: id))
    }

    package func moveReading(id: UUID, to index: Int) {
        setReadingList(data.prefs.reading.list.moving(id: id, to: index))
    }

    package func markReadingDone(id: UUID) {
        setReadingList(data.prefs.reading.list.markingDone(id: id, on: today))
    }

    package var canUndoReading: Bool { data.prefs.reading.list.unread.count < Limits.readingListMax }

    package func undoReadingDone(id: UUID) {
        setReadingList(data.prefs.reading.list.undoingDone(id: id))
    }

    package func finishReading(markDone: Bool) {
        let target = session(.reading) == nil ? readingPick : readingSessionItem
        if session(.reading) != nil { finishSession(.reading) }
        if markDone, let target { markReadingDone(id: target.id) }
    }

    private var today: DayKey { DayKey(clock.now, calendar: calendar) }

    private func setReadingList(_ list: [ReadingItem]) {
        if list != data.prefs.reading.list { data.prefs.reading.list = list }
    }
}
