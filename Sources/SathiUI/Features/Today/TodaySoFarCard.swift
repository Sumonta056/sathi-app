import SathiCore
import SwiftUI

struct TodaySoFarCard: View {
    let sofar: TodaySoFar
    let categories: [ActivityCategory]
    let calendar: Calendar
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todaySoFarGap) {
            header
            if sofar.isOn, let hours = sofar.hours {
                ActivityRibbon(
                    segments: sofar.segments, hours: hours, categories: categories,
                    height: UIMetrics.todayRibbonHeight, radius: UIMetrics.todayRibbonRadius, showsLabels: false
                )
                .overlay(nowMarker(hours))
                ActivityAxis(hours: hours, calendar: calendar)
                    .overlay(nowLabel(hours))
                if !sofar.categories.isEmpty || !sofar.away.isEmpty {
                    TodaySoFarBreakdown(sofar: sofar, categories: categories)
                }
            } else if !sofar.isOn {
                Text(verbatim: Copywriter.todaySoFarOffHint)
                    .font(Typography.tracker(UIMetrics.todayPanelNoteFont, .regular))
                    .foregroundStyle(Night.muted)
            }
        }
        .padding(UIMetrics.todayPanelPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .todayCard()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: UIMetrics.todayComingRowGap) {
            Text(verbatim: Copywriter.todaySoFarTitle)
                .font(Typography.tracker(UIMetrics.todayPanelTitleFont, .heavy))
                .foregroundStyle(Night.text)
            Spacer(minLength: 0)
            if sofar.isOn {
                Text(verbatim: Copywriter.categoryTableHours(sofar.logged))
                    .font(Typography.tracker(UIMetrics.todaySoFarTotalFont, .heavy))
                    .foregroundStyle(Night.text)
                if sofar.change != .none {
                    Text(verbatim: Copywriter.todaySoFarChange(sofar.change))
                        .font(Typography.tracker(UIMetrics.todayComingDetailFont, .heavy))
                        .foregroundStyle(changeColor)
                }
                Text(verbatim: Copywriter.todayLoggedSummary(percent: TodayShare.percent(logged: sofar.logged, hours: sofar.hours, now: now)))
                    .font(Typography.tracker(UIMetrics.todayComingDetailFont, .regular))
                    .foregroundStyle(Night.muted)
            }
        }
    }

    private var changeColor: Color {
        if case .up = sofar.change { return Night.sprout }
        return Night.muted
    }

    private func fraction(_ hours: DateInterval) -> CGFloat? {
        guard hours.contains(now) else { return nil }
        return CGFloat(now.timeIntervalSince(hours.start) / max(hours.duration, 1))
    }

    @ViewBuilder
    private func nowLabel(_ hours: DateInterval) -> some View {
        if let fraction = fraction(hours) {
            GeometryReader { g in
                Text(verbatim: Copywriter.todayNowAt(now, calendar: calendar))
                    .font(Typography.hint.weight(.heavy))
                    .foregroundStyle(Night.text)
                    .fixedSize()
                    .position(
                        x: min(max(g.size.width * fraction, UIMetrics.todayNowLabelHalfWidth), g.size.width - UIMetrics.todayNowLabelHalfWidth),
                        y: g.size.height / 2
                    )
            }
        }
    }

    @ViewBuilder
    private func nowMarker(_ hours: DateInterval) -> some View {
        if let fraction = fraction(hours) {
            marker(fraction)
        }
    }

    private func marker(_ fraction: CGFloat) -> some View {
        GeometryReader { g in
            Rectangle()
                .fill(Night.text)
                .frame(width: UIMetrics.todayNowMarkerWidth, height: g.size.height)
                .offset(x: g.size.width * fraction)
        }
        .accessibilityLabel(Copywriter.todayNowMarker)
    }
}

extension View {
    func todayCard() -> some View {
        background(RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous).fill(Night.card))
            .overlay(RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous).stroke(Night.border))
    }
}
