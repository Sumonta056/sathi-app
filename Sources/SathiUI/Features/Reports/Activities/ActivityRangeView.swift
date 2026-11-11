import SathiCore
import SwiftUI

struct ActivityRangeView: View {
    let range: StatsRange
    let days: [ActivityDay]
    let stats: ActivityRangeStats
    let categories: [ActivityCategory]
    let calendar: Calendar
    let now: Date
    var actions = ActivityRangeActions()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
                ActivityTableCard(table: ActivityTableCard.range(stats.categories, categories: categories))
                tiles
                ReportsCard {
                    ForEach(keys, id: \.self) { key in
                        ActivityMonthRowView(
                            day: key, row: byDay[key], categories: categories, calendar: calendar
                        ) { actions.openDay(key) }
                        Divider().overlay(Night.divider)
                    }
                }
                ActivityTextCard(
                    title: Copywriter.activitiesRangeTextTitle,
                    text: ActivityRangeText.make(days, title: Copywriter.rangeTitle(range, now: now, calendar: calendar), calendar: calendar),
                    copy: actions.copy
                )
            }
            .padding(.bottom, UIMetrics.reportsGap)
        }
    }

    private var keys: [DayKey] { range.days.map { DayKey($0.start, calendar: calendar) } }

    private var byDay: [DayKey: ActivityMonthRow] {
        Dictionary(stats.rows.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var tiles: some View {
        HStack(spacing: UIMetrics.trackerTileSpacing) {
            ActivityTile(
                label: Copywriter.trackerTileRealWork, value: Copywriter.categoryTableHours(stats.realWork),
                note: Copywriter.trackerDaysTracked(stats.rows.count), change: stats.realWorkChange, changeText: text(stats.realWorkChange)
            )
            ActivityTile(
                label: Copywriter.trackerTileAverageDay, value: Copywriter.categoryTableHours(stats.averageDay),
                note: "", change: stats.averageDayChange, changeText: text(stats.averageDayChange)
            )
            ActivityTile(
                label: Copywriter.trackerTileBestDay,
                value: stats.bestDay.map { Copywriter.categoryTableHours($0.realWork) } ?? Copywriter.noValue,
                note: stats.bestDay.map { Copywriter.trackerShortDate($0.day.start(in: calendar), calendar: calendar) } ?? "",
                accent: Night.sprout, change: stats.bestDayChange, changeText: text(stats.bestDayChange)
            )
            ActivityTile(
                label: Copywriter.trackerTileAway, value: Copywriter.categoryTableHours(stats.away),
                note: "", accent: Night.trackerAway, change: stats.awayChange, changeText: text(stats.awayChange)
            )
        }
    }

    private func text(_ change: RangeChange) -> String {
        Copywriter.rangeChange(change, kind: range.kind) { Copywriter.categoryTableHours($0) }
    }
}
