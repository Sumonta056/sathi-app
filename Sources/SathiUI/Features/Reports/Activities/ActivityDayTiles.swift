import SathiCore
import SwiftUI

struct ActivityDayTiles: View {
    let overview: ActivityDayOverview

    var body: some View {
        VStack(spacing: UIMetrics.activitiesTileGap) {
            HStack(spacing: UIMetrics.activitiesTileGap) {
                ActivityDayTile(label: Copywriter.activitiesTileLogged, value: duration(overview.logged), note: loggedNote, noteColor: loggedColor)
                ActivityDayTile(
                    label: Copywriter.activitiesTileFocus, value: duration(overview.focus),
                    note: Copywriter.activitiesFocusNote(overview.focusPercent)
                )
            }
            HStack(spacing: UIMetrics.activitiesTileGap) {
                ActivityDayTile(
                    label: Copywriter.activitiesTileAway, value: duration(overview.away),
                    note: Copywriter.activitiesAwayNote(overview.awayCount, place: overview.topPlace)
                )
                ActivityDayTile(
                    label: Copywriter.activitiesTileCount, value: overview.count == .zero ? Copywriter.activitiesNoData : "\(overview.count)",
                    note: Copywriter.activitiesTopNote(overview.topCategory)
                )
            }
        }
    }

    private func duration(_ seconds: TimeInterval) -> String {
        seconds >= Timing.minute ? Copywriter.activitiesLength(seconds) : Copywriter.activitiesNoData
    }

    private var loggedNote: String { Copywriter.activitiesLoggedNote(overview.loggedChange, kind: .day) }

    private var loggedColor: Color {
        if case .up = overview.loggedChange { return Night.sprout }
        return Night.muted
    }
}

struct ActivityDayTile: View {
    let label: String
    let value: String
    let note: String
    var noteColor = Night.muted

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.activitiesTileRadius, style: .continuous)
        VStack(alignment: .leading, spacing: UIMetrics.activitiesTileLineGap) {
            Text(verbatim: label)
                .font(Typography.tracker(UIMetrics.activitiesTileLabelFont, .bold))
                .foregroundStyle(Night.muted)
            Text(verbatim: value)
                .font(Typography.tracker(UIMetrics.activitiesTileValueFont, .heavy))
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .minimumScaleFactor(UIMetrics.trackerTileMinScale)
            Text(verbatim: note)
                .font(Typography.tracker(UIMetrics.activitiesTileNoteFont, .medium))
                .foregroundStyle(noteColor)
                .lineLimit(1)
        }
        .padding(UIMetrics.activitiesTilePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }
}
