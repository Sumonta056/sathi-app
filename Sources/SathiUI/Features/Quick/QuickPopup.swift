import SathiCore
import SwiftUI

struct QuickPopup: View {
    @EnvironmentObject var e: Engine
    let id: UUID
    let level: Level

    @State private var shakes: CGFloat = 0

    var body: some View {
        if let item = e.quick(id) {
            let canSnooze = e.canSnoozeQuick(id)
            VStack(alignment: .leading, spacing: UIMetrics.cornerSpacing) {
                header(item, canSnooze: canSnooze)
                HStack(spacing: UIMetrics.cornerButtonSpacing) {
                    Button { e.quickDone(id) } label: {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AccentButton(accent: Night.quick, height: UIMetrics.quickButtonHeight))
                    if canSnooze {
                        Button { e.snoozeQuick(id) } label: { Text(e.snoozeShortLabel) }
                            .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.quickButtonHeight))
                    }
                }
            }
            .modifier(CornerCard(alert: level == .persist || !canSnooze, border: Night.quickBorder, alertColor: Night.quick))
            .modifier(Shake(amount: shakes))
            .task(id: level) { await shakeWhilePersisting() }
        }
    }

    private func header(_ item: QuickReminder, canSnooze: Bool) -> some View {
        let calendar = Calendar.gregorian(in: e.timeZone)
        return HStack(alignment: .top, spacing: UIMetrics.cornerRowSpacing) {
            Image(systemName: "bell")
                .font(.system(size: UIMetrics.quickTileIcon, weight: .semibold))
                .foregroundStyle(Night.quick)
                .frame(width: UIMetrics.quickTileSize, height: UIMetrics.quickTileSize)
                .background(RoundedRectangle(cornerRadius: UIMetrics.quickTileRadius, style: .continuous).fill(Night.quickFill))
            VStack(alignment: .leading, spacing: UIMetrics.cornerTextSpacing) {
                Text(verbatim: Copywriter.quickEyebrow(due: item.due, calendar: calendar))
                    .font(Typography.eyebrow)
                    .foregroundStyle(Night.quick)
                Text(verbatim: item.text)
                    .font(Typography.cornerTitle)
                    .foregroundStyle(Night.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: canSnooze ? Copywriter.quickSetAt(item.createdAt, calendar: calendar) : Copywriter.quickNoSnooze)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if e.showsQuickClose(id) {
                CornerCloseButton(label: "Dismiss") { e.snoozeQuick(id) }
            }
        }
    }

    private func shakeWhilePersisting() async {
        guard level == .persist else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(UIMetrics.shakeInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: UIMetrics.shakeDuration)) { shakes += 1 }
        }
    }
}
