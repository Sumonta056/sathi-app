import SathiCore
import SwiftUI

struct TimeBlockCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        if let b = e.timeBlock {
            VStack(alignment: .leading, spacing: UIMetrics.blockCardSpacing) {
                if b.waitingForCalendar {
                    header
                    WaitingSaveAction(idPrefix: "block.")
                } else {
                    BlockRunningRow(block: b).id(b.id)
                }
            }
            .blockCardStyle()
        } else if e.calendarAccess == .denied {
            VStack(alignment: .leading, spacing: UIMetrics.blockCardSpacing) {
                header
                noAccess
            }
            .blockCardStyle()
        }
    }

    private var header: some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            Image(systemName: "timer")
                .font(.system(size: UIMetrics.blockHeaderIcon, weight: .semibold))
                .foregroundStyle(Night.block)
            Text(verbatim: Copywriter.blockCardTitle)
                .font(Typography.cardTitle)
                .foregroundStyle(Night.text)
        }
    }

    private var noAccess: some View {
        VStack(alignment: .leading, spacing: UIMetrics.blockCardSpacing) {
            Text(verbatim: Copywriter.blockNoAccess)
                .font(Typography.hint)
                .foregroundStyle(Night.chipText)
                .fixedSize(horizontal: false, vertical: true)
            accentButton(Copywriter.blockOpenSettings, id: "block.openSettings") { e.openCalendarSettings() }
        }
    }

    private func accentButton(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(Typography.chip)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(id)
        }
        .buttonStyle(AccentButton(accent: Night.block, height: UIMetrics.blockStartHeight, radius: UIMetrics.blockButtonRadius))
    }
}
