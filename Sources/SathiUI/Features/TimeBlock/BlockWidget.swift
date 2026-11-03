import SathiCore
import SwiftUI

struct BlockWidget: View {
    @EnvironmentObject var e: Engine
    @State private var hovering = false

    var body: some View {
        if let b = e.timeBlock, b.isRunning {
            pill(b)
                .padding(UIMetrics.bubbleShadowPadding)
                .environment(\.colorScheme, .dark)
        }
    }

    private func pill(_ b: TimeBlock) -> some View {
        HStack(spacing: UIMetrics.blockWidgetSpacing) {
            BlockRing(progress: BlockRing.progress(b, now: e.now), size: UIMetrics.blockWidgetRing, line: UIMetrics.blockWidgetRingLine)
            BlockWidgetTitle(title: b.title, hint: Self.hint(b, e), hovering: hovering)
            BlockWidgetTimer(block: b)
            endButton
        }
        .padding(UIMetrics.blockWidgetPadding)
        .frame(width: UIMetrics.blockWidgetWidth, height: UIMetrics.blockWidgetHeight)
        .background(Capsule().fill(Night.card))
        .overlay(Capsule().strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
        .onHover { hovering = $0 }
    }

    private var endButton: some View {
        Button { e.endBlock() } label: {
            Image(systemName: "xmark")
                .font(.system(size: UIMetrics.blockWidgetEndIcon, weight: .heavy))
                .foregroundStyle(Night.chipText)
                .frame(width: UIMetrics.blockWidgetEnd, height: UIMetrics.blockWidgetEnd)
                .background(Circle().fill(Night.bg))
                .contentShape(Circle())
                .accessibilityIdentifier("block.widget.end")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Copywriter.blockEndAndSave)
        .help(Copywriter.blockEndAndSave)
    }

    static func timer(_ b: TimeBlock) -> (range: ClosedRange<Date>, countsDown: Bool) {
        if let end = b.plannedEnd { return (b.startedAt ... max(b.startedAt, end), true) }
        return (b.startedAt ... b.startedAt.addingTimeInterval(Timing.blockCap), false)
    }

    static func hint(_ b: TimeBlock, _ e: Engine) -> String {
        let name = e.calendarTitle(b.calendarID) ?? b.calendarTitle ?? Copywriter.blockYourCalendar
        return Copywriter.blockWidgetHint(
            end: b.plannedEnd, start: b.startedAt, calendarTitle: name, calendar: Calendar.gregorian(in: e.timeZone)
        )
    }
}

struct BlockWidgetTitle: View {
    let title: String
    let hint: String
    let hovering: Bool

    var body: some View {
        Text(verbatim: hovering ? hint : title)
            .font(hovering ? Typography.hint : Typography.chip)
            .foregroundStyle(hovering ? Night.muted : Night.text)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BlockWidgetTimer: View {
    let block: TimeBlock

    var body: some View {
        let t = BlockWidget.timer(block)
        Text(timerInterval: t.range, pauseTime: nil, countsDown: t.countsDown, showsHours: true)
            .font(Typography.chip)
            .monospacedDigit()
            .foregroundStyle(Night.block)
            .fixedSize()
            .accessibilityIdentifier("block.widget.timer")
    }
}
