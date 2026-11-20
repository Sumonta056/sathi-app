import SathiCore
import SwiftUI

struct ActivityEditSection: View {
    @State var draft: ActivityEditDraft
    let title: String
    let accent: Color
    let categories: [ActivityCategory]
    let calendars: [CalendarChoice]
    var places: [String] = []
    var calendarNames: [String: String] = [:]
    let dayStart: Date
    let calendar: Calendar
    let save: (ActivityEdit) -> ActivityEditResult
    let delete: (() -> Bool)?
    let close: () -> Void
    @State var message: String?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.activitiesEditRadius, style: .continuous)
        VStack(alignment: .leading, spacing: UIMetrics.activitiesEditGap) {
            header
            if draft.canSwitchKind { ActivityEditAwaySwitch(draft: $draft, defaultCategory: categories.first?.name) }
            if draft.isAway {
                ActivityEditPlaces(draft: $draft, places: places)
            } else {
                VStack(alignment: .leading, spacing: UIMetrics.activitiesFieldGap) {
                    ActivityFieldLabel(text: Copywriter.activitiesFieldName)
                    LazyTextField(placeholder: Copywriter.trackerFieldPlaceholder, text: $draft.text, startsEditing: draft.text.isEmpty)
                        .padding(.horizontal, UIMetrics.activitiesRowInner)
                        .frame(height: UIMetrics.activitiesFieldHeight)
                        .background(RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous).fill(Night.bg))
                        .overlay(RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous)
                            .strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
                }
            }
            ActivityEditTimes(draft: $draft, accent: shownAccent)
            ActivityEditChoices(draft: $draft, categories: categories, calendars: calendars, calendarNames: calendarNames)
            Divider().overlay(Night.border)
            footer
            if let message {
                Text(verbatim: message).font(Typography.hint).foregroundStyle(Night.cheek)
            }
        }
        .padding(UIMetrics.activitiesEditPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(shape.fill(Night.trackerInset))
        .overlay(shape.strokeBorder(shownAccent.opacity(UIMetrics.activitiesPencilTint), lineWidth: UIMetrics.cardBorder))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: title))
    }

    private var shownAccent: Color {
        guard draft.kindChange != nil else { return accent }
        return draft.isAway ? Night.chipText : ActivityColors.color(draft.category, in: categories)
    }

    private var header: some View {
        HStack(spacing: UIMetrics.activitiesRowDetailGap) {
            RoundedRectangle(cornerRadius: UIMetrics.activitiesEditMark.width / 2)
                .fill(shownAccent)
                .frame(width: UIMetrics.activitiesEditMark.width, height: UIMetrics.activitiesEditMark.height)
            Text(verbatim: title)
                .font(Typography.tracker(UIMetrics.activitiesTitleFont, .heavy))
                .foregroundStyle(Night.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: UIMetrics.activitiesRowIcon, weight: .bold))
                    .foregroundStyle(Night.chipText)
                    .frame(width: UIMetrics.activitiesEditClose, height: UIMetrics.activitiesEditClose)
                    .background(RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous).fill(Night.card))
                    .overlay(RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous)
                        .strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: Copywriter.activitiesClose))
        }
    }

    private var footer: some View {
        HStack(spacing: UIMetrics.activitiesChipGap) {
            if let delete {
                Button(Copywriter.trackerDelete) { message = delete() ? nil : Copywriter.activitiesDeleteFailed }
                    .buttonStyle(GhostButton(accent: Night.cheek, height: UIMetrics.activitiesFieldHeight))
            }
            Spacer(minLength: 0)
            Button(Copywriter.trackerCancel) { close() }
                .buttonStyle(GhostButton(accent: Night.muted, height: UIMetrics.activitiesFieldHeight))
            Button(Copywriter.trackerSave) { submit() }
                .buttonStyle(AccentButton(accent: Night.tracker, height: UIMetrics.activitiesFieldHeight, text: Night.trackerOnAccent))
        }
    }

    private func submit() {
        let result = save(draft.edit(dayStart: dayStart, calendar: calendar))
        let text = ActivityEditDraft.message(result)
        message = text
        if text == nil { close() }
    }
}
