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
            HStack(alignment: .top, spacing: UIMetrics.tileGap) {
                ReportsCard {
                    ActivityLogView(day: day, categories: categories, calendar: calendar, actions: actions)
                }
                VStack(spacing: UIMetrics.tileGap) {
                    ReportsCard {
                        Text(verbatim: Copywriter.activitiesTotalsTitle).font(Typography.rowLabel).foregroundStyle(Night.text)
                        ActivityCategoryBars(totals: stats.categories, categories: categories)
                    }
                    ActivityTextCard(
                        title: Copywriter.activitiesStandupTitle,
                        text: ActivityStandupText.make(day, calendar: calendar), copy: actions.copy
                    )
                }
                .frame(width: UIMetrics.activitiesSideWidth)
            }
            .padding(.bottom, UIMetrics.reportsGap)
        }
    }
}
