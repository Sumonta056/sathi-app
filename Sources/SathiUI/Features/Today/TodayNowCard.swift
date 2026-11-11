import SathiCore
import SwiftUI

struct TodayNowCard: View {
    let e: Engine
    let now: TodayNow
    let calendar: Calendar

    var body: some View {
        switch now {
        case let .running(minutes, text, category, since, nextAsk):
            running(minutes: minutes, text: text, category: category, since: since, nextAsk: nextAsk)
        case let .idle(nextAsk):
            idle(nextAsk: nextAsk)
        case .off:
            off
        }
    }

    private func running(minutes: Int, text: String, category: String?, since: Date, nextAsk: Date?) -> some View {
        card {
            Text(verbatim: Copywriter.todayNowMinutes(minutes))
                .font(Typography.tracker(UIMetrics.todayNowRingFont, .heavy))
                .foregroundStyle(Night.trackerSelectedText)
                .frame(width: UIMetrics.todayNowRing, height: UIMetrics.todayNowRing)
                .overlay(Circle().stroke(Night.tracker, lineWidth: UIMetrics.todayNowRingLine))
            texts(
                title: text,
                detail: Copywriter.todayNowDetail(category: category, since: since, nextAsk: nextAsk, calendar: calendar)
            )
            Button { e.openTrackerPanel() } label: { Text(verbatim: Copywriter.todaySwitch) }
                .buttonStyle(AccentButton(
                    accent: Night.tracker, height: UIMetrics.todayNowButtonHeight,
                    radius: UIMetrics.todayButtonRadius, text: Night.trackerOnAccent, padding: UIMetrics.todayNowButtonPadding
                ))
            Button { e.doneActivity() } label: { Text(verbatim: Copywriter.todayStop) }
                .buttonStyle(OutlineNowButton())
        }
    }

    private func idle(nextAsk: Date?) -> some View {
        card(neutral: true) {
            texts(
                title: Copywriter.trackerNotTracking,
                detail: nextAsk.map { Copywriter.todayIdleDetail(nextAsk: $0, calendar: calendar) }
            )
            Button { e.openTrackerPanel() } label: { Text(verbatim: Copywriter.todayLogActivity) }
                .buttonStyle(AccentButton(
                    accent: Night.tracker, height: UIMetrics.todayNowButtonHeight,
                    radius: UIMetrics.todayButtonRadius, text: Night.trackerOnAccent, padding: UIMetrics.todayNowButtonPadding
                ))
        }
    }

    private var off: some View {
        card(neutral: true) {
            texts(title: Copywriter.todayTrackerOff, detail: nil)
            Button { e.openSettings(.tracker) } label: { Text(verbatim: Copywriter.todayTurnOn) }
                .buttonStyle(OutlineNowButton())
        }
    }

    private func texts(title: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.todayNowTextGap) {
            Text(verbatim: Copywriter.todayNowLabel)
                .font(Typography.tracker(UIMetrics.todayNowLabelFont, .bold))
                .tracking(UIMetrics.todayNowLabelTracking)
                .foregroundStyle(Night.tracker)
            Text(verbatim: title)
                .font(Typography.tracker(UIMetrics.todayNowTitleFont, .bold))
                .foregroundStyle(Night.text)
                .lineLimit(1)
            if let detail {
                Text(verbatim: detail)
                    .font(Typography.tracker(UIMetrics.todayNowDetailFont, .regular))
                    .foregroundStyle(Night.trackerNowText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func card(neutral: Bool = false, @ViewBuilder _ content: () -> some View) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous)
        return HStack(spacing: UIMetrics.todayNowGap, content: content)
            .padding(UIMetrics.todayNowPadding)
            .background(shape.fill(neutral ? Night.card : Night.trackerFill))
            .overlay(shape.stroke(neutral ? Night.border : Night.trackerNowBorder))
    }
}

struct OutlineNowButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.todayButtonRadius, style: .continuous)
        return configuration.label
            .font(Typography.tracker(UIMetrics.todayButtonFont, .semibold))
            .foregroundStyle(Night.trackerSelectedText)
            .padding(.horizontal, UIMetrics.todayNowButtonPadding)
            .frame(height: UIMetrics.todayNowButtonHeight)
            .overlay(shape.stroke(Night.trackerStopBorder))
            .opacity(configuration.isPressed ? UIMetrics.pressedOpacity : 1)
            .contentShape(shape)
    }
}
