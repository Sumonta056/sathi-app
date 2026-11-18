import SathiCore
import SwiftUI

struct CalendarHoverCard: View {
    let info: CalendarHoverInfo
    let actions: [CalendarHoverAction]
    let run: (CalendarHoverAction) -> Void
    var pick: (String) -> Void = { _ in }

    private var timeLine: String {
        [info.time, info.length].compactMap { $0 }.joined(separator: Copywriter.calendarHoverMetaSeparator)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarHoverRadius, style: .continuous)
        VStack(alignment: .leading, spacing: UIMetrics.calendarHoverSpacing) {
            Text(verbatim: info.kindLabel)
                .font(Typography.tracker(UIMetrics.calendarHoverKindFont, .semibold))
                .foregroundStyle(Night.faint)
            Text(verbatim: info.title)
                .font(Typography.tracker(UIMetrics.calendarHoverTitleFont, .bold))
                .foregroundStyle(Night.text)
                .fixedSize(horizontal: false, vertical: true)
            line(timeLine, color: Night.text)
            if let meta = info.meta { line(meta, color: Night.muted) }
            if let childrenTitle = info.childrenTitle { rows(childrenTitle, info.children) }
            if let alsoHereTitle = info.alsoHereTitle { rows(alsoHereTitle, info.alsoHere, picks: true) }
            if !actions.isEmpty { buttons }
        }
        .padding(UIMetrics.calendarHoverPadding)
        .frame(width: UIMetrics.calendarHoverWidth, alignment: .leading)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
        .contentShape(shape)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calendar.hover.card")
    }

    private func line(_ text: String, color: Color) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarHoverLineFont, .medium))
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private func rows(_ title: String, _ items: [CalendarHoverChild], picks: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.calendarHoverChildGap) {
            Text(verbatim: title)
                .font(Typography.tracker(UIMetrics.calendarHoverKindFont, .semibold))
                .foregroundStyle(Night.faint)
            ForEach(items) { item in
                if picks {
                    Button { pick(item.id) } label: { row(item) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("calendar.hover.also." + item.id)
                } else {
                    row(item)
                }
            }
        }
    }

    private func row(_ item: CalendarHoverChild) -> some View {
        HStack(spacing: UIMetrics.calendarHoverButtonGap) {
            Text(verbatim: item.title).foregroundStyle(Night.text).lineLimit(1)
            Spacer(minLength: 0)
            Text(verbatim: item.time).foregroundStyle(Night.muted).lineLimit(1).fixedSize()
        }
        .font(Typography.tracker(UIMetrics.calendarHoverChildFont, .medium))
        .contentShape(Rectangle())
    }

    private var buttons: some View {
        VStack(spacing: UIMetrics.calendarHoverButtonGap) {
            if let first = actions.first { button(first, kind: .primary) }
            HStack(spacing: UIMetrics.calendarHoverButtonGap) {
                ForEach(actions.dropFirst(), id: \.self) { button($0, kind: $0 == .delete ? .danger : .ghost) }
            }
        }
    }

    private func button(_ action: CalendarHoverAction, kind: PillButton.Kind) -> some View {
        Button(Copywriter.calendarHoverAction(action)) { run(action) }
            .buttonStyle(CalendarHoverButtonStyle(kind: kind))
            .accessibilityIdentifier("calendar.hover.action." + String(describing: action))
    }
}

struct CalendarHoverButtonStyle: ButtonStyle {
    let kind: PillButton.Kind

    func makeBody(configuration: Configuration) -> some View {
        let pair = PillButton.colors(kind)
        return configuration.label
            .font(Typography.tracker(UIMetrics.calendarHoverLineFont, .semibold))
            .lineLimit(1)
            .minimumScaleFactor(UIMetrics.calendarHoverButtonScale)
            .padding(.horizontal, UIMetrics.calendarHoverButtonPadding)
            .frame(maxWidth: .infinity, minHeight: UIMetrics.calendarHoverButtonHeight)
            .foregroundStyle(pair.fg)
            .background(RoundedRectangle(cornerRadius: UIMetrics.calendarHoverButtonRadius, style: .continuous).fill(pair.bg))
            .opacity(configuration.isPressed ? UIMetrics.pillPressedOpacity : 1)
            .contentShape(Rectangle())
    }
}
