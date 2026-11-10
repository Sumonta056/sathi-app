import SathiCore
import SwiftUI

struct ActivityMonthView: View {
    let month: MonthKey
    let days: [ActivityDay]
    let categories: [ActivityCategory]
    var calendar: Calendar = .current
    var actions = ActivityMonthActions()
    @State private var copied = false

    var body: some View {
        let stats = ActivityMonthStats(days)
        ScrollView {
            VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
                header
                tiles(stats)
                ReportsCard {
                    ForEach(stats.rows) { row in
                        ActivityMonthRowView(row: row, categories: categories, calendar: calendar) { actions.openDay(row.day) }
                        Divider().overlay(Night.divider)
                    }
                }
                ReportsCard {
                    Text(verbatim: Copywriter.trackerByCategory).font(Typography.rowLabel).foregroundStyle(Night.text)
                    ActivityCategoryBars(totals: stats.categories, categories: categories)
                }
            }
            .padding(.bottom, UIMetrics.reportsGap)
        }
    }

    private var header: some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            arrow("chevron.left", "Previous month", month.previous)
            Text(verbatim: Copywriter.trackerMonthTitle(month.start(in: calendar), calendar: calendar))
                .font(Typography.heroTitle).foregroundStyle(Night.text)
            arrow("chevron.right", "Next month", month.next)
            Spacer(minLength: 0)
            Button(copied ? Copywriter.trackerCopied : Copywriter.trackerCopyMonthly) {
                actions.copy(ActivityMonthText.make(days, month: month, calendar: calendar))
                copied = true
            }
            .buttonStyle(GhostButton(accent: Night.tracker))
            Button(Copywriter.trackerExportMonth) { actions.exportMonth() }
                .buttonStyle(GhostButton(accent: Night.tracker))
        }
    }

    private func arrow(_ symbol: String, _ label: String, _ target: MonthKey) -> some View {
        Button { actions.selectMonth(target) } label: {
            Image(systemName: symbol)
                .foregroundStyle(Night.tracker)
                .frame(width: UIMetrics.trackerNavButton, height: UIMetrics.trackerNavButton)
                .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.card))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
    }

    private func tiles(_ stats: ActivityMonthStats) -> some View {
        HStack(spacing: UIMetrics.trackerTileSpacing) {
            ActivityTile(
                label: Copywriter.trackerTileRealWork,
                value: Copywriter.trackerTileDuration(stats.realWork),
                note: "\(stats.daysTracked) days"
            )
            ActivityTile(label: Copywriter.trackerTileAverageDay, value: Copywriter.trackerTileDuration(stats.averageDay), note: "")
            ActivityTile(
                label: Copywriter.trackerTileBestDay,
                value: stats.bestDay.map { Copywriter.trackerTileDuration($0.realWork) } ?? "–",
                note: stats.bestDay.map { Copywriter.trackerShortDate($0.day.start(in: calendar), calendar: calendar) } ?? "",
                accent: Night.sprout
            )
            ActivityTile(label: Copywriter.trackerTileAway, value: Copywriter.trackerTileDuration(stats.away), note: "", accent: Night.trackerAway)
        }
    }
}
