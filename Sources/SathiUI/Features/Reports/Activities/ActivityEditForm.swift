import SathiCore
import SwiftUI

struct ActivityEditForm: View {
    @State var draft: ActivityEditDraft
    let categories: [ActivityCategory]
    let dayStart: Date
    let calendar: Calendar
    let save: (ActivityEdit) -> ActivityEditResult
    let delete: (() -> Void)?
    let close: () -> Void
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            LazyTextField(placeholder: Copywriter.trackerFieldPlaceholder, text: $draft.text, startsEditing: draft.text.isEmpty)
            HStack(spacing: UIMetrics.sectionSpacing) {
                TimeMenu(minutes: $draft.startMinutes, accent: Night.tracker)
                Text(verbatim: "–").foregroundStyle(Night.muted)
                TimeMenu(minutes: $draft.endMinutes, accent: Night.tracker)
                categoryMenu
                Spacer(minLength: 0)
                if let delete {
                    Button(Copywriter.trackerDelete) { delete() }
                        .buttonStyle(GhostButton(accent: Night.cheek, height: UIMetrics.trackerMiniButton))
                }
                Button(Copywriter.trackerCancel) { close() }
                    .buttonStyle(GhostButton(accent: Night.muted, height: UIMetrics.trackerMiniButton))
                Button(Copywriter.trackerSave) { submit() }
                    .buttonStyle(AccentButton(accent: Night.tracker, height: UIMetrics.trackerMiniButton))
            }
            if let message {
                Text(verbatim: message).font(Typography.hint).foregroundStyle(Night.cheek)
            }
        }
        .padding(UIMetrics.trackerLogRowPadding)
        .background(RoundedRectangle(cornerRadius: UIMetrics.trackerMiniRadius, style: .continuous).fill(Night.trackerRowSelected))
    }

    private var categoryMenu: some View {
        Menu {
            Button(Copywriter.trackerNoCategory) { draft.category = nil }
            ForEach(categories) { c in Button(c.name) { draft.category = c.name } }
        } label: {
            Text(verbatim: draft.category ?? Copywriter.trackerNoCategory)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func submit() {
        let result = save(draft.edit(dayStart: dayStart, calendar: calendar))
        let text = ActivityEditDraft.message(result)
        message = text
        if text == nil { close() }
    }
}
