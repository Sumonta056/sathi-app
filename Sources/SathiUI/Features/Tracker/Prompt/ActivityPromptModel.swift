import SathiCore
import SwiftUI

@MainActor
final class ActivityPromptModel: ObservableObject {
    @Published var draft: ActivityDraft
    @Published var started: Date?
    @Published var showsStarted = false
    @Published var showsAll = false
    @Published var calendars: TrackerCalendarInfo
    @Published var awayOn = false
    @Published var awayPick: PromptAwayPick?
    @Published var awayAdding = false
    @Published var awayNewName = ""
    let places: PromptWhereForm
    private let nowChoice: Date?
    private let allowsAway: Bool
    var answered = false
    private var asking = false

    init(_ state: TrackerPromptState) {
        var draft = state.draft
        if let event = state.event, state.kind == .eventAsk, draft.text.isEmpty { draft.text = event.title }
        self.draft = draft
        let screen = ActivityPromptBuilder.screen(state)
        nowChoice = screen.startedChoices.last
        allowsAway = screen.allowsAway
        started = nowChoice
        calendars = TrackerCalendarInfo(access: state.calendarAccess, calendars: state.calendars, defaultID: state.defaultCalendarID)
        places = PromptWhereForm(state)
    }

    var switchAt: Date? {
        started == nowChoice ? nil : started
    }

    func carry(from old: ActivityPromptModel) {
        draft.text = old.draft.text
        draft.category = old.draft.category
        guard allowsAway else { return }
        awayOn = old.awayOn
        awayPick = old.awayPick
    }

    func fill(_ recent: RecentActivity) {
        draft = draft.filled(from: recent)
    }

    func fill(_ event: CalendarEventInfo) {
        draft = draft.filled(from: event)
    }

    func pick(category: String) {
        draft.category = draft.category == category ? nil : category
    }

    func pick(length: ActivityLength) {
        draft = draft.with(length: length)
    }

    func allowCalendar(_ ask: @escaping @MainActor () async -> TrackerCalendarInfo?) {
        guard !asking else { return }
        asking = true
        Task { @MainActor in
            defer { asking = false }
            guard let answer = await ask() else { return }
            calendars = answer
            if let id = answer.tickID { draft.calendarID = id }
        }
    }
}
