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
    var placeNames: [String] = []
    var addedPlaces: [String] = []
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
        s.actions.pickPlaceName = { calls.placeNames.append($0) }
        s.actions.addPlace = { calls.addedPlaces.append($0) }
        s.actions.notAttending = { calls.notAttending.append($0) }
        s.actions.answerEvent = {
            calls.answers.append($0)
            calls.calls.append("answer:\($0)")
        }
        s.actions.pickEventCategory = { calls.calls.append("category:" + $0) }
        s.actions.close = { calls.calls.append("close") }
        s.actions.allowCalendar = {
            calls.calls.append("allowCalendar")
            return nil
        }
        s.actions.openCalendarSettings = { calls.calls.append("openCalendarSettings") }
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

    static func chipIsOn(_ view: InspectableView<some BaseViewType>, _ id: String) throws -> Bool {
        let chips = view.findAll(TrackerChip.self).compactMap { try? $0.actualView() }
        guard let chip = chips.first(where: { $0.id == id }) else { throw PromptRowMissing(id: id, row: 0, count: 0) }
        return chip.on
    }

    static func buttonText(_ view: InspectableView<some BaseViewType>, _ id: String) throws -> [String] {
        try texts(view.find(viewWithAccessibilityIdentifier: id).find(ViewType.Button.self, relation: .parent))
    }

    static func ids(_ view: InspectableView<some BaseViewType>, prefix: String) -> [String] {
        view.findAll(where: { (try? $0.accessibilityIdentifier())?.hasPrefix(prefix) == true })
            .compactMap { try? $0.accessibilityIdentifier() }
    }

    static func texts(_ view: InspectableView<some BaseViewType>) -> [String] {
        view.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    static func hasText(_ view: InspectableView<some BaseViewType>, _ text: String) -> Bool {
        texts(view).contains(text)
    }

    static func tap(_ view: InspectableView<some BaseViewType>, _ id: String, row: Int) throws {
        let rows = view.findAll(where: { (try? $0.accessibilityIdentifier()) == id })
        guard rows.indices.contains(row) else { throw PromptRowMissing(id: id, row: row, count: rows.count) }
        try rows[row].find(ViewType.Button.self, relation: .parent).tap()
    }

    static func boxIsOn(_ view: InspectableView<some BaseViewType>, _ id: String) throws -> Bool {
        let boxes = view.findAll(PromptBox.self).compactMap { try? $0.actualView() }
        guard let box = boxes.first(where: { $0.id == id }) else { throw PromptRowMissing(id: id, row: 0, count: boxes.count) }
        return box.on
    }

    static func categoryList(_ view: InspectableView<some BaseViewType>) throws -> InspectableView<ViewType.ClassifiedView> {
        try view.find(TrackerCategoryMenu.self).actualView().list.inspect()
    }

    static func recents(_ count: Int) -> [RecentActivity] {
        (0 ..< count).map { RecentActivity(text: "Task \($0)", category: $0 == 3 ? "Review" : "Coding", length: 1800) }
    }

    static func view(
        _ state: TrackerPromptState,
        model: ActivityPromptModel? = nil
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try ActivityPromptView(state: state, model: model).inspect()
    }
}

struct PromptRowMissing: Error {
    let id: String
    let row: Int
    let count: Int
}
