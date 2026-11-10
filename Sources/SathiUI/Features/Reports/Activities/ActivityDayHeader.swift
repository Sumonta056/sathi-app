import SathiCore
import SwiftUI

struct ActivityDayHeader: View {
    let day: ActivityDay
    let stats: ActivityDayStats
    let calendar: Calendar
    let actions: ActivityDayActions
    @State private var picking = false
    @State private var copied = false

    var body: some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            nav("chevron.left", "Previous day", step: -1)
            Button { picking = true } label: {
                VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                    Text(verbatim: Copywriter.trackerLongDate(start, calendar: calendar))
                        .font(Typography.heroTitle).foregroundStyle(Night.text)
                    Text(verbatim: Copywriter.trackerDayFacts(count: stats.count, away: stats.away, notLogged: stats.notLogged))
                        .font(Typography.hint).foregroundStyle(Night.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $picking, arrowEdge: .bottom) {
                ActivityDatePicker(selected: day.day, calendar: calendar, marks: actions.marks) {
                    picking = false
                    actions.select($0)
                }
            }
            nav("chevron.right", "Next day", step: 1)
            Spacer(minLength: 0)
            Button(copied ? Copywriter.trackerCopied : Copywriter.trackerCopyAsText) {
                actions.copy(ActivityStandupText.make(day, calendar: calendar))
                copied = true
            }
            .buttonStyle(GhostButton(accent: Night.tracker))
        }
    }

    private var start: Date { day.day.start(in: calendar) }

    private func nav(_ symbol: String, _ label: String, step: Int) -> some View {
        Button {
            let moved = calendar.date(byAdding: .day, value: step, to: start) ?? start
            actions.select(DayKey(moved, calendar: calendar))
        } label: {
            Image(systemName: symbol)
                .foregroundStyle(Night.tracker)
                .frame(width: UIMetrics.trackerNavButton, height: UIMetrics.trackerNavButton)
                .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.card))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
    }
}
