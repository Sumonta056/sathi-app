import Foundation
import SathiCore
import SathiTestSupport

enum PromptFixture {
    static let zone = FixedZone.berlin
    static var calendar: Calendar { zone.calendar }

    static func at(_ h: Int, _ m: Int = 0) -> Date { zone.date(2026, 3, 4, h, m) }

    static func clock(_ date: Date) -> String { Copywriter.trackerClock(date, calendar: calendar) }

    static func running(_ text: String = "Code review", from start: Date = at(10), length: ActivityLength = .minutes(30)) -> RunningActivity {
        let askAt = length.interval.map { start.addingTimeInterval($0) } ?? start
        return RunningActivity(text: text, category: "Coding", start: start, expectedLength: length, askAt: askAt)
    }

    static let event = CalendarEventInfo(id: "e1", title: "Design sync", start: at(12), end: at(13), calendarID: "work")

    static func state(_ kind: PromptKind, now: Date = at(10, 30), _ configure: (inout TrackerPromptState) -> Void = { _ in }) -> TrackerPromptState {
        var s = TrackerPromptState(kind: kind, shownAt: now, now: now, draft: ActivityDraft(text: ""))
        s.calendar = calendar
        s.askEveryMinutes = 15
        s.shortcut = .trackerDefault
        switch kind {
        case .stillOnIt:
            s.running = running()
        case .welcomeBack:
            s.away = AwaySpan(start: at(9, 55), end: at(10, 30), cause: .asleep)
            s.lastActivity = ActivityDraft(text: "Code review")
        case .eventAsk:
            s.event = event
            s.eventCalendarTitle = "Work"
        case .todoDue:
            s.todos = [makeTodo("a", "Write report", due: TodoDue(date: at(10, 30), hasTime: true))]
        case .whatNow, .center:
            break
        }
        configure(&s)
        return s
    }

    static func screen(
        _ kind: PromptKind,
        now: Date = at(10, 30),
        _ configure: (inout TrackerPromptState) -> Void = { _ in }
    ) -> ActivityPromptScreen {
        ActivityPromptBuilder.screen(state(kind, now: now, configure))
    }
}
