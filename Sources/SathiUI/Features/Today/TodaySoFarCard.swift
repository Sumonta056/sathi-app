import SathiCore
import SwiftUI

struct TodaySoFarCard: View {
    let sofar: TodaySoFar
    let categories: [ActivityCategory]
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todayPanelGap) {
            HStack {
                Text(verbatim: Copywriter.todaySoFarTitle)
                    .font(Typography.tracker(UIMetrics.todayPanelTitleFont, .bold))
                    .foregroundStyle(Night.text)
                Spacer(minLength: 0)
                if sofar.isOn {
                    Text(verbatim: Copywriter.todayLogged(sofar.logged))
                        .font(Typography.tracker(UIMetrics.todayPanelNoteFont, .regular))
                        .foregroundStyle(Night.muted)
                }
            }
            if sofar.isOn, let hours = sofar.hours {
                ActivityRibbon(
                    segments: sofar.segments, hours: hours, categories: categories,
                    height: UIMetrics.todayRibbonHeight, radius: UIMetrics.todayRibbonRadius, showsLabels: false
                )
                ActivityAxis(hours: hours, calendar: calendar)
                legend
            } else if !sofar.isOn {
                Text(verbatim: Copywriter.todaySoFarOffHint)
                    .font(Typography.tracker(UIMetrics.todayPanelNoteFont, .regular))
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(UIMetrics.todayPanelPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous).fill(Night.card))
        .overlay(RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous).stroke(Night.border))
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todayLegendGap) {
            ForEach(sofar.categories) { total in
                HStack(spacing: UIMetrics.todayLegendGap) {
                    Circle()
                        .fill(ActivityColors.color(total.isNamed ? total.name : nil, in: categories))
                        .frame(width: UIMetrics.todayLegendDot, height: UIMetrics.todayLegendDot)
                    Text(verbatim: total.name)
                        .foregroundStyle(Night.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: Copywriter.trackerDuration(total.seconds))
                        .foregroundStyle(Night.muted)
                }
                .font(Typography.tracker(UIMetrics.todayLegendFont, .regular))
            }
        }
    }
}
