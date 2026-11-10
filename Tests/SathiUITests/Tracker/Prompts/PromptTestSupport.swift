import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import ViewInspector

final class PromptCalls {
    var started: [(ActivityDraft, Date?)] = []
    var skipped: [Date?] = []
    var stillOn: [Int?] = []
    var calls: [String] = []
    var places: [AwayPlace] = []
    var notAttending: [String] = []
    var answers: [Bool] = []
    var continued: [Date?] = []
}

@MainActor
enum Prompt {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)
    static let zone = TimeZone(identifier: "UTC") ?? .current

    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = zone
        return c
    }

    static func state(
        _ kind: PromptKind,
        calls: PromptCalls = PromptCalls(),
        configure: (inout TrackerPromptState) -> Void = { _ in }
    ) -> TrackerPromptState {
        var s = TrackerPromptState(kind: kind, shownAt: now, now: now, draft: ActivityDraft(text: "Write spec", category: "Coding"))
        s.calendar = calendar
        s.categories = ActivityCategory.defaults
        s.calendars = [CalendarChoice(id: "work", title: "Work", account: "iCloud", colorHex: 0x4CC3F5)]
        s.actions.start = { calls.started.append(($0, $1)) }
        s.actions.skip = { calls.skipped.append($0) }
        s.actions.stillOn = { calls.stillOn.append($0) }
        s.actions.stillOnLate = { calls.calls.append("stillLate") }
        s.actions.done = { calls.calls.append("done") }
        s.actions.continueLast = { calls.continued.append($0) }
        s.actions.backToLast = { calls.calls.append("back") }
        s.actions.iWasHere = { calls.calls.append("here") }
        s.actions.pickPlace = { calls.places.append($0) }
        s.actions.notAttending = { calls.notAttending.append($0) }
        s.actions.answerEvent = { calls.answers.append($0) }
        s.actions.close = { calls.calls.append("close") }
        configure(&s)
        return s
    }

    static func event(_ title: String = "Standup") -> CalendarEventInfo {
        CalendarEventInfo(id: "e1", title: title, start: now, end: now.addingTimeInterval(1800), calendarID: "work")
    }

    static func tap(_ view: InspectableView<some BaseViewType>, _ id: String) throws {
        try view.find(viewWithAccessibilityIdentifier: id).find(ViewType.Button.self, relation: .parent).tap()
    }

    static func has(_ view: InspectableView<some BaseViewType>, _ id: String) -> Bool {
        (try? view.find(viewWithAccessibilityIdentifier: id)) != nil
    }
}
