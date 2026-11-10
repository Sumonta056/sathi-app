import SathiCore
import SwiftUI

struct TrackerNoteView: View {
    let state: TrackerNoteState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerNoteCardSpacing) {
            TrackerHeader(
                icon: "calendar",
                eyebrow: Copywriter.trackerFromCalendar(event.start, calendar: state.calendar),
                title: title,
                detail: Copywriter.trackerEventSpan(event, calendarTitle: state.calendarTitle ?? "", calendar: state.calendar)
            )
            if !isAlsoNow {
                TrackerNoteCategoryRow(categories: state.categories, selected: state.category, idPrefix: "tracker.note.category.") {
                    state.actions.pickCategory($0)
                }
            }
            HStack(spacing: UIMetrics.trackerButtonSpacing) {
                if isAlsoNow {
                    TrackerPrimaryButton(
                        label: Copywriter.trackerSwitch, id: "tracker.note.switch", height: UIMetrics.trackerNoteButton,
                        radius: UIMetrics.trackerNoteButtonRadius, font: UIMetrics.trackerOutlineFont
                    ) { state.actions.switchToEvent() }
                    button(Copywriter.trackerNotAttending, "tracker.note.notAttending") { state.actions.notAttending() }
                } else {
                    button(Copywriter.trackerNotAttending, "tracker.note.notAttending") { state.actions.notAttending() }
                    button(Copywriter.trackerUndo, "tracker.note.undo") { state.actions.undo() }
                }
            }
            if let footer { TrackerHint(text: footer) }
        }
        .trackerCornerCard()
    }

    private var event: CalendarEventInfo { state.note.event }

    private var isAlsoNow: Bool {
        if case .alsoNow = state.note { return true }
        return false
    }

    private var title: String {
        isAlsoNow ? Copywriter.trackerAlsoNow(event.title) : event.title
    }

    private var footer: String? {
        if let ended = state.endedText { return Copywriter.trackerEventEnded(ended, at: event.start, calendar: state.calendar) }
        return isAlsoNow ? nil : Copywriter.trackerNoteCloses
    }

    private func button(_ label: String, _ id: String, action: @escaping () -> Void) -> some View {
        TrackerSecondaryButton(
            label: label, id: id, height: UIMetrics.trackerNoteButton, radius: UIMetrics.trackerNoteButtonRadius,
            font: UIMetrics.trackerOutlineFont, weight: .bold, color: Night.text, action: action
        )
    }
}

struct TrackerNoteCategoryRow: View {
    let categories: [ActivityCategory]
    let selected: String?
    let idPrefix: String
    let onPick: (String) -> Void

    var body: some View {
        HStack(spacing: UIMetrics.trackerNoteRowGap) {
            Text(verbatim: Copywriter.trackerCategory)
                .font(Typography.tracker(TrackerSize.corner.label, .bold))
                .foregroundStyle(Night.label)
                .frame(width: TrackerSize.corner.labelWidth, alignment: .leading)
            TrackerCategoryMenu(
                categories: categories, selected: selected, idPrefix: idPrefix,
                allowsNone: false, compact: true, fill: Night.trackerInset
            ) { name in
                if let name { onPick(name) }
            }
        }
    }
}
