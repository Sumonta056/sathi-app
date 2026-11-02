import Foundation

package struct TimeBlock: Codable, Equatable, Identifiable, Sendable {
    package var id: UUID
    package var title: String
    package var startedAt: Date
    package var length: TimeBlockLength
    package var plannedEnd: Date?
    package var calendarID: String
    package var savedEventID: String?
    package var nextCheckIn: Date?
    package var endedAt: Date?
    package var waitingForCalendar = false

    package init(title: String, startedAt: Date, length: TimeBlockLength, calendarID: String) {
        id = UUID()
        self.title = title
        self.startedAt = startedAt
        self.length = length
        self.calendarID = calendarID
        plannedEnd = length.minutes.map { startedAt.addingTimeInterval(Double($0) * Timing.minute) }
        nextCheckIn = length == .open ? startedAt.addingTimeInterval(Timing.blockCheckIn) : nil
    }

    var isRunning: Bool { !waitingForCalendar }

    func draft(end: Date) -> CalendarEventDraft {
        CalendarEventDraft(calendarID: calendarID, title: title, start: startedAt, end: end)
    }
}

extension TimeBlock {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try TimeBlockText.clean(c.decode(String.self, forKey: .title))
        startedAt = try c.decode(Date.self, forKey: .startedAt).wholeSecond
        length = try c.decode(TimeBlockLength.self, forKey: .length)
        plannedEnd = c.lenient(.plannedEnd, or: Date?.none)?.wholeSecond
        calendarID = try c.decode(String.self, forKey: .calendarID)
        savedEventID = c.lenient(.savedEventID, or: String?.none)
        nextCheckIn = c.lenient(.nextCheckIn, or: Date?.none)?.wholeSecond
        endedAt = c.lenient(.endedAt, or: Date?.none)?.wholeSecond
        waitingForCalendar = c.lenient(.waitingForCalendar, or: false)
    }
}

package struct FinishedBlock: Equatable, Sendable {
    package var block: TimeBlock
    package var end: Date
    package var calendarTitle: String
}

package enum BlockNote: Equatable, Sendable {
    case started(title: String, length: TimeBlockLength, end: Date?, calendarTitle: String)
    case savedPrevious(minutes: Int, title: String, calendarTitle: String)
    case tooShort
}

package enum BlockStartResult: Equatable, Sendable {
    case started(UUID)
    case noAccess
    case noCalendar
    case blockWaiting
}
