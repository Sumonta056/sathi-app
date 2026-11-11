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
                Text(verbatim: Fmt.short(sofar.logged))
                    .font(Typography.tracker(UIMetrics.todaySoFarTotalFont, .heavy))
                    .foregroundStyle(Night.text)
                Text(verbatim: Copywriter.todayLoggedSummary(percent: TodayShare.percent(logged: sofar.logged, hours: sofar.hours, now: now)))
                    .font(Typography.tracker(UIMetrics.todayComingDetailFont, .regular))
                    .foregroundStyle(Night.muted)
            }
        }
    }

    private func nowMarker(_ hours: DateInterval) -> some View {
        GeometryReader { g in
            let fraction = max(0, min(1, now.timeIntervalSince(hours.start) / max(hours.duration, 1)))
            Rectangle()
                .fill(Night.text)
                .frame(width: UIMetrics.todayNowMarkerWidth, height: g.size.height)
                .offset(x: g.size.width * CGFloat(fraction))
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
