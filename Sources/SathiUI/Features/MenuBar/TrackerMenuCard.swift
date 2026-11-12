import SathiCore
import SwiftUI

struct TrackerMenuCard: View {
    let running: RunningActivity?
    let now: Date
    let next: Date?
    let calendar: Calendar
    let accent: Color
    let shortcut: String
    let onDone: () -> Void
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerMenuCardSpacing) {
            if let running {
                runningRow(running)
                Rectangle().fill(Night.tracker.opacity(UIMetrics.chipFillOpacity)).frame(height: UIMetrics.cardBorder)
                switchRow
            } else {
                idleRow
            }
        }
        .padding(UIMetrics.trackerMenuCardPadding)
        .background(shape.fill(Night.trackerFill))
        .overlay(shape.strokeBorder(Night.tracker.opacity(UIMetrics.chipFillOpacity), lineWidth: UIMetrics.cardBorder))
    }

    private func runningRow(_ r: RunningActivity) -> some View {
        HStack(spacing: UIMetrics.trackerMenuRowSpacing) {
            Circle().fill(accent).frame(width: UIMetrics.trackerMenuDot, height: UIMetrics.trackerMenuDot)
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: r.text).font(Typography.rowLabel).foregroundStyle(Night.text).lineLimit(1)
                hint(Copywriter.trackerSinceFor(r.start, now: now, calendar: calendar))
            }
            Spacer(minLength: 0)
            Button(action: onDone) {
                Text(verbatim: Copywriter.trackerMenuDone)
                    .font(Typography.chip)
                    .foregroundStyle(Night.tracker)
                    .padding(.horizontal, UIMetrics.chipPadding)
                    .frame(height: UIMetrics.trackerMenuDoneHeight)
                    .overlay(Pill().strokeBorder(Night.tracker, lineWidth: UIMetrics.chipBorder))
                    .contentShape(Pill())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu.tracker.done")
        }
    }

    private var switchRow: some View {
        ViewThatFits(in: .horizontal) {
            switchContent(showsShortcut: true)
            switchContent(showsShortcut: false)
        }
    }

    private func switchContent(showsShortcut: Bool) -> some View {
        HStack(spacing: UIMetrics.trackerMenuRowSpacing) {
            Button(action: onLog) {
                HStack(spacing: UIMetrics.chipSpacing) {
                    pencil
                    Text(verbatim: Copywriter.trackerSwitchActivity).font(Typography.chip).lineLimit(1)
                }
                .fixedSize()
                .foregroundStyle(Night.tracker)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu.tracker.log")
            if showsShortcut {
                Text(verbatim: shortcut).font(Typography.hint).foregroundStyle(Night.faint).fixedSize()
            }
            Spacer(minLength: 0)
            if let next { hint(Copywriter.trackerNextAsk(next, calendar: calendar)).fixedSize() }
        }
    }

    private var idleRow: some View {
        HStack(spacing: UIMetrics.trackerMenuRowSpacing) {
            Circle().strokeBorder(Night.muted, lineWidth: UIMetrics.chipBorder)
                .frame(width: UIMetrics.trackerMenuDot, height: UIMetrics.trackerMenuDot)
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: Copywriter.trackerNotTracking).font(Typography.rowLabel).foregroundStyle(Night.chipText)
                if let next { hint(Copywriter.trackerNextAsk(next, calendar: calendar)) }
            }
            Spacer(minLength: 0)
            Button(action: onLog) {
                HStack(spacing: UIMetrics.chipSpacing) {
                    pencil
                    Text(verbatim: Copywriter.trackerLogActivity).font(Typography.chip)
                }
                .foregroundStyle(Night.trackerOnAccent)
                .padding(.horizontal, UIMetrics.chipPadding)
                .frame(height: UIMetrics.trackerMenuDoneHeight)
                .background(Pill().fill(Night.tracker))
                .contentShape(Pill())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu.tracker.log")
        }
    }

    private var pencil: some View {
        Image(systemName: "pencil.line")
            .font(.system(size: UIMetrics.trackerMenuIcon, weight: .heavy))
            .accessibilityHidden(true)
    }

    private func hint(_ text: String) -> some View {
        Text(verbatim: text).font(Typography.hint).foregroundStyle(Night.muted).lineLimit(1)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}

struct TrackerMenuSlot: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if e.data.prefs.tracker.isOn {
            TrackerMenuCard(
                running: e.runningActivity, now: e.now, next: e.trackerNextPopup, calendar: .current,
                accent: e.runningActivity.map { Self.accent($0, e) } ?? Night.tracker,
                shortcut: Copywriter.trackerShortcut(e.data.prefs.tracker.shortcut),
                onDone: { e.doneActivity() }, onLog: { e.openTrackerPanel() }
            )
        }
    }

    static func accent(_ running: RunningActivity, _ engine: Engine) -> Color {
        let hex = engine.activityCategories.first { $0.name == running.category }?.colorHex
        return hex.map { Color(hex: $0) } ?? Night.tracker
    }
}
