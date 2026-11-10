import SathiCore
import SwiftUI

struct EndOfDayView: View {
    let state: TrackerEndOfDayState
    var copy: (String) -> Void = ActivityPasteboard.copy
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var copied = false
    @State private var playID = 0

    var body: some View {
        let stats = ActivityDayStats(state.day)
        VStack(alignment: .leading, spacing: UIMetrics.trackerEndOfDaySpacing) {
            Text(verbatim: Copywriter.trackerYourDayEyebrow(state.day.day.start(in: state.calendar), calendar: state.calendar))
                .font(Typography.eyebrow).tracking(UIMetrics.labelTracking).foregroundStyle(Night.tracker)
            Text(verbatim: Copywriter.trackerRealWork(stats.realWork))
                .font(.system(size: UIMetrics.trackerEndOfDayTitleFont, weight: .black, design: .rounded))
                .foregroundStyle(Night.text)
            Text(verbatim: Copywriter.trackerDayFacts(count: stats.count, away: stats.away, notLogged: stats.notLogged))
                .font(Typography.hint).foregroundStyle(Night.muted)
            EndOfDayRibbon(day: state.day, stats: stats, categories: state.categories, reduceMotion: reduceMotion).id(playID)
            ActivityAxis(hours: state.day.hours, calendar: state.calendar)
            ActivityCategoryBars(totals: stats.categories, categories: state.categories)
            if stats.notLogged > 0 {
                Button(Copywriter.trackerFillInReport) { state.openReport() }
                    .buttonStyle(.plain).font(Typography.hint).foregroundStyle(Night.trackerEvent)
            }
            buttons
            if copied { Text(verbatim: Copywriter.trackerCopiedStandup).font(Typography.hint).foregroundStyle(Night.sprout) }
        }
        .padding(UIMetrics.trackerPanelPadding)
        .frame(width: UIMetrics.trackerEndOfDayWidth, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: UIMetrics.trackerPanelRadius, style: .continuous).fill(Night.card))
        .overlay(
            RoundedRectangle(cornerRadius: UIMetrics.trackerPanelRadius, style: .continuous)
                .strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder)
        )
    }

    private var buttons: some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            Button(Copywriter.trackerCopyForStandup) {
                copy(ActivityStandupText.make(state.day, calendar: state.calendar))
                copied = true
            }
            .buttonStyle(AccentButton(accent: Night.tracker))
            Button(Copywriter.trackerOpenFullReport) { state.openReport() }.buttonStyle(GhostButton(accent: Night.tracker))
            Button(Copywriter.trackerPlayAgain) { playID += 1 }.buttonStyle(GhostButton(accent: Night.muted))
            Spacer(minLength: 0)
            Button(Copywriter.trackerClose) { state.close() }.buttonStyle(GhostButton(accent: Night.muted))
        }
    }
}
