import SathiCore
import SwiftUI

struct BlockRunningRow: View {
    @EnvironmentObject var e: Engine
    let block: TimeBlock
    @State private var draft: String?

    var body: some View {
        let elapsed = max(0, e.now.timeIntervalSince(block.startedAt))
        VStack(alignment: .leading, spacing: UIMetrics.blockCardSpacing) {
            HStack(spacing: UIMetrics.blockRowSpacing) {
                BlockRing(progress: BlockRing.progress(block, now: e.now))
                    .overlay(
                        Text(verbatim: Copywriter.blockMinutes(minutes(elapsed)))
                            .font(Typography.chip)
                            .foregroundStyle(Night.text)
                    )
                VStack(alignment: .leading, spacing: UIMetrics.blockTextSpacing) {
                    LazyTextField(placeholder: Copywriter.blockDefaultTitle, text: title, onSubmit: commit, onEndEditing: commit)
                    Text(verbatim: line(elapsed))
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                }
            }
            HStack(spacing: UIMetrics.chipSpacing) {
                CalendarMenu(selection: Binding(get: { block.calendarID }, set: { e.setBlockCalendar($0) }))
                Button { e.endBlock() } label: { Text(verbatim: Copywriter.blockEndNow) }
                    .buttonStyle(AccentButton(accent: Night.block, height: UIMetrics.blockActionHeight))
            }
        }
        .onDisappear(perform: commit)
    }

    private var title: Binding<String> {
        Binding(get: { draft ?? block.title }, set: { draft = $0 })
    }

    private func commit() {
        if let draft, draft != block.title { e.renameBlock(draft) }
        draft = nil
    }

    private func minutes(_ elapsed: TimeInterval) -> Int { Int(elapsed / Timing.minute) }

    private func line(_ elapsed: TimeInterval) -> String {
        let calendar = Calendar.gregorian(in: e.timeZone)
        guard let end = block.plannedEnd else {
            return Copywriter.blockSince(start: block.startedAt, minutes: minutes(elapsed), calendar: calendar)
        }
        let total = Int((end.timeIntervalSince(block.startedAt) / Timing.minute).rounded())
        return Copywriter.blockProgress(elapsed: minutes(elapsed), total: total, end: end, calendar: calendar)
    }
}
