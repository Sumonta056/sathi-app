import SathiCore
import SwiftUI

struct ActivityDayView: View {
    let day: ActivityDay
    let categories: [ActivityCategory]
    var calendar: Calendar = .current
    var actions = ActivityDayActions()

    var body: some View {
        let stats = ActivityDayStats(day)
        ScrollView {
            VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
                ActivityDayHeader(day: day, stats: stats, calendar: calendar, actions: actions)
                tiles(stats)
                ReportsCard {
                    Text(verbatim: Copywriter.trackerTimeline).font(Typography.rowLabel).foregroundStyle(Night.text)
                    ActivityRibbon(segments: stats.segments, hours: day.hours, categories: categories)
                    ActivityAxis(hours: day.hours, calendar: calendar)
                }
                ReportsCard {
                    Text(verbatim: Copywriter.trackerActivityLog).font(Typography.rowLabel).foregroundStyle(Night.text)
                    ActivityLogView(day: day, categories: categories, calendar: calendar, actions: actions)
                }
                ReportsCard {
                    Text(verbatim: Copywriter.trackerByCategory).font(Typography.rowLabel).foregroundStyle(Night.text)
                    ActivityCategoryBars(totals: stats.categories, categories: categories)
                }
            }
            .padding(.bottom, UIMetrics.reportsGap)
        }
    }

    private func tiles(_ stats: ActivityDayStats) -> some View {
        let percent = stats.tracked > 0 ? Int(stats.realWork / stats.tracked * Double(Limits.fullPercent)) : 0
        let top = stats.topCategory
        return HStack(spacing: UIMetrics.trackerTileSpacing) {
            ActivityTile(
                label: Copywriter.trackerTileRealWork,
                value: Copywriter.trackerTileDuration(stats.realWork),
                note: Copywriter.trackerPercentOfHours(percent)
            )
            ActivityTile(
                label: Copywriter.trackerTileTopCategory,
                value: top?.name ?? "–",
                note: top.map { Copywriter.trackerDuration($0.seconds) } ?? "",
                accent: ActivityColors.color(top?.name, in: categories)
            )
            ActivityTile(
                label: Copywriter.trackerTileActivities,
                value: "\(stats.count)",
                note: Copywriter.trackerInYourCalendar(stats.inCalendar),
                accent: Night.trackerEvent
            )
            ActivityTile(
                label: Copywriter.trackerTileAway,
                value: Copywriter.trackerTileDuration(stats.away),
                note: stats.notLogged > 0 ? Copywriter.trackerNotLoggedAmount(stats.notLogged) : Copywriter.trackerNothingMissing,
                accent: Night.trackerAway
            )
        }
    }
}
