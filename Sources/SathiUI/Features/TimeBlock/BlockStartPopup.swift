import SathiCore
import SwiftUI

struct BlockStartPopup: View {
    @EnvironmentObject var e: Engine
    @State private var title = ""
    @State private var length: TimeBlockLength?
    @State private var calendarID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.blockPopupSpacing) {
            header
            LazyTextField(placeholder: Copywriter.blockDefaultTitle, text: $title, startsEditing: true, onSubmit: start)
                .modifier(QuickTextLimit(text: $title, limit: Limits.blockTitleMax))
                .frame(height: UIMetrics.blockFieldHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                        .strokeBorder(Night.block, lineWidth: UIMetrics.blockFieldBorder)
                )
            LengthChips(selection: Binding(get: { chosenLength }, set: { length = $0 }))
            CalendarMenu(selection: Binding(get: { chosenCalendar }, set: { calendarID = $0 }))
            Button(action: start) {
                Text(verbatim: Copywriter.blockStartLabel(end: end, calendar: Calendar.gregorian(in: e.timeZone)))
                    .font(Typography.rowLabel)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("block.start")
            }
            .buttonStyle(AccentButton(accent: Night.block, height: UIMetrics.blockStartButtonHeight, radius: UIMetrics.blockButtonRadius))
            .disabled(chosenCalendar.isEmpty)
        }
        .modifier(CornerCard(width: UIMetrics.blockPopupWidth, border: Night.border))
        .onExitCommand { e.cancelBlockStart() }
    }

    private var chosenLength: TimeBlockLength { length ?? e.data.prefs.timeBlock.lastLength }

    private var chosenCalendar: String { calendarID ?? e.startCalendarID ?? "" }

    private var end: Date? {
        chosenLength.minutes.map { e.now.addingTimeInterval(Double($0) * Timing.minute) }
    }

    private var header: some View {
        HStack(spacing: UIMetrics.blockRowSpacing) {
            Image(systemName: "timer")
                .font(.system(size: UIMetrics.blockTileIcon, weight: .semibold))
                .foregroundStyle(Night.block)
                .frame(width: UIMetrics.blockTileSize, height: UIMetrics.blockTileSize)
                .background(tile.fill(Night.blockFill))
                .overlay(tile.strokeBorder(Night.blockBorder, lineWidth: UIMetrics.cardBorder))
            VStack(alignment: .leading, spacing: UIMetrics.blockNoteTextSpacing) {
                Text(verbatim: Copywriter.blockEyebrow)
                    .font(Typography.eyebrow)
                    .foregroundStyle(Night.block)
                Text(verbatim: Copywriter.blockPrompt)
                    .font(Typography.cornerTitle)
                    .foregroundStyle(Night.text)
            }
            Spacer(minLength: 0)
            CornerCloseButton(label: "Close") { e.cancelBlockStart() }
        }
    }

    private var tile: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.blockButtonRadius, style: .continuous)
    }

    private func start() {
        guard !chosenCalendar.isEmpty else { return }
        e.startBlock(title: title, length: chosenLength, calendarID: chosenCalendar)
    }
}
