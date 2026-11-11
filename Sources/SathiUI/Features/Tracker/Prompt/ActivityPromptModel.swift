import SathiCore
import SwiftUI

@MainActor
final class ActivityPromptModel: ObservableObject {
    @Published var draft: ActivityDraft
    @Published var started: Date?
    @Published var showsStarted = false
    @Published var showsAll = false
    @Published var calendars: TrackerCalendarInfo
    let places: PromptWhereForm
    private let nowChoice: Date?
    var answered = false
    private var asking = false

    init(_ state: TrackerPromptState) {
        var draft = state.draft
        if let event = state.event, state.kind == .eventAsk, draft.text.isEmpty { draft.text = event.title }
        self.draft = draft
        nowChoice = ActivityPromptBuilder.screen(state).startedChoices.last
        started = nowChoice
        calendars = TrackerCalendarInfo(access: state.calendarAccess, calendars: state.calendars, defaultID: state.defaultCalendarID)
        places = PromptWhereForm(state)
    }

    var switchAt: Date? {
        started == nowChoice ? nil : started
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
