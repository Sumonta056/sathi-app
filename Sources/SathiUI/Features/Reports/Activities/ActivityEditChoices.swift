import SathiCore
import SwiftUI

struct ActivityEditChoices: View {
    @Binding var draft: ActivityEditDraft
    let categories: [ActivityCategory]
    let calendars: [CalendarChoice]
    var calendarNames: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.activitiesEditGap) {
            if !draft.isAway {
                ActivityFieldLabel(text: Copywriter.activitiesFieldCategory)
                TrackerFlowLayout(spacing: UIMetrics.activitiesChipGap) {
                    ForEach(categories) { c in
                        PromptBox(
                            label: c.name, on: draft.category == c.name, id: "activity.category." + c.name,
                            look: .activityEdit(Night.category(c.colorHex))
                        ) { draft.category = c.name }
                    }
                    PromptBox(
                        label: Copywriter.activitiesNoCategory, on: draft.category == nil, id: "activity.category.none",
                        look: .activityEdit(Night.promptSecondary)
                    ) { draft.category = nil }
                }
            }
            if draft.showsCalendar {
                ActivityFieldLabel(text: Copywriter.activitiesFieldCalendar)
                TrackerFlowLayout(spacing: UIMetrics.activitiesChipGap) {
                    PromptBox(
                        label: Copywriter.activitiesNoCalendar, on: draft.calendarID == nil, id: "activity.calendar.none",
                        look: .activityEdit(Night.promptSecondary)
                    ) { draft.pickCalendar(nil) }
                    if let unlisted = draft.unlistedCalendarID {
                        PromptBox(
                            label: calendarNames[unlisted] ?? Copywriter.activitiesCurrentCalendar, on: draft.keepsCalendar,
                            id: "activity.calendar.current", look: .activityEdit(Night.promptSecondary)
                        ) { draft.pickCalendar(unlisted) }
                    }
                    ForEach(calendars) { c in
                        PromptBox(
                            label: c.title, on: !draft.keepsCalendar && draft.calendarID == c.id, id: "activity.calendar." + c.id,
                            look: .activityEdit(Night.trackerEvent)
                        ) { draft.pickCalendar(c.id) }
                    }
                }
            }
        }
    }
}

struct ActivityEditPlaces: View {
    @Binding var draft: ActivityEditDraft
    var places: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.activitiesFieldGap) {
            ActivityFieldLabel(text: Copywriter.activitiesFieldPlace)
            TrackerFlowLayout(spacing: UIMetrics.activitiesChipGap) {
                ForEach(builtIns, id: \.self) { place in
                    chip(Copywriter.trackerAwayPlace(place), on: draft.awayPlace == place && !isUserPlace, id: "report.place." + place.rawValue) {
                        draft.pickPlace(place)
                    }
                }
                ForEach(places, id: \.self) { name in
                    chip(name, on: draft.awayPlace == .other && draft.awayPlaceName == name, id: "report.place.custom." + name) {
                        draft.pickPlace(named: name)
                    }
                }
                chip(otherLabel, on: draft.awayPlace == .other && !isUserPlace, id: "report.place.other") {
                    draft.pickPlace(.other)
                }
            }
        }
    }

    private var builtIns: [AwayPlace] {
        let main = AwayPlace.choices.filter { $0 != .other }
        return draft.awayPlace == .breakTime ? main + [.breakTime] : main
    }

    private var isUserPlace: Bool {
        draft.awayPlace == .other && draft.awayPlaceName.map(places.contains) == true
    }

    private var otherLabel: String {
        isUserPlace ? Copywriter.trackerAwayPlace(.other) : draft.awayPlaceName ?? Copywriter.trackerAwayPlace(.other)
    }

    private func chip(_ label: String, on: Bool, id: String, action: @escaping () -> Void) -> some View {
        PromptBox(label: label, on: on, id: id, look: .activityEdit(Night.chipText), action: action)
    }
}
