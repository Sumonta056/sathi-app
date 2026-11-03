import SathiCore
import SwiftUI

struct WaitingSaveAction: View {
    @EnvironmentObject var e: Engine
    let idPrefix: String

    var body: some View {
        switch e.waitingSaveState {
        case .noAccess where e.calendarAccess == .notAsked:
            accentButton(Copywriter.blockAllowCalendarAccess, id: idPrefix + "allowAccess") {
                Task { await e.requestCalendarAccess() }
            }
        case .noAccess:
            accentButton(Copywriter.blockOpenSettings, id: idPrefix + "openSettings") { e.openCalendarSettings() }
        case .noCalendar:
            Text(verbatim: Copywriter.blockNoWritableCalendar)
                .font(Typography.hint)
                .foregroundStyle(Night.chipText)
                .fixedSize(horizontal: false, vertical: true)
        case .choose:
            BlockSaveHere(idPrefix: idPrefix)
        }
    }

    private func accentButton(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(Typography.rowLabel)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(id)
        }
        .buttonStyle(AccentButton(accent: Night.block, height: UIMetrics.blockStartHeight, radius: UIMetrics.blockButtonRadius))
    }
}
