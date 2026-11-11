import SathiCore
import SwiftUI

struct ActivityEditChoices: View {
    @Binding var draft: ActivityEditDraft
    let categories: [ActivityCategory]
    let calendars: [CalendarChoice]

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
                    ) { draft.calendarID = nil }
                    ForEach(calendars) { c in
                        PromptBox(
                            label: c.title, on: draft.calendarID == c.id, id: "activity.calendar." + c.id,
                            look: .activityEdit(Night.trackerEvent)
                        ) { draft.calendarID = c.id }
                    }
                }
            }
        }
    }
}

struct ActivityEditPlaces: View {
    @Binding var draft: ActivityEditDraft

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.activitiesFieldGap) {
            ActivityFieldLabel(text: Copywriter.activitiesFieldPlace)
            TrackerFlowLayout(spacing: UIMetrics.activitiesChipGap) {
                ForEach(AwayPlace.allCases, id: \.self) { place in
                    PromptBox(
                        label: label(place),
                        on: draft.awayPlace == place,
                        id: "report.place." + place.rawValue,
                        look: .activityEdit(Night.chipText)
                    ) {
                        draft.awayPlace = place
                        draft.awayPlaceName = nil
                    }
                }
            }
        }
    }

    private func label(_ place: AwayPlace) -> String {
        place == .other ? draft.awayPlaceName ?? Copywriter.trackerAwayPlace(place) : Copywriter.trackerAwayPlace(place)
    }
}
