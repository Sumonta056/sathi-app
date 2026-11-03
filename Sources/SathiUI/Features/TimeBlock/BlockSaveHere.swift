import SathiCore
import SwiftUI

struct BlockSaveHere: View {
    @EnvironmentObject var e: Engine
    var idPrefix = "block."

    var body: some View {
        let id = e.waitingSaveCalendarID ?? ""
        VStack(alignment: .leading, spacing: UIMetrics.blockCardSpacing) {
            BlockCalendarList(
                selection: Binding(get: { id }, set: { e.pickWaitingCalendar($0) }),
                idPrefix: idPrefix + "choice."
            )
            Button(action: save) {
                Text(verbatim: Copywriter.blockSaveHere)
                    .font(Typography.rowLabel)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(idPrefix + "saveHere")
            }
            .buttonStyle(AccentButton(accent: Night.block, height: UIMetrics.blockStartHeight, radius: UIMetrics.blockButtonRadius))
            .disabled(id.isEmpty)
        }
    }

    private func save() {
        guard let id = e.waitingSaveCalendarID else { return }
        e.saveWaitingBlock(to: id)
    }
}
