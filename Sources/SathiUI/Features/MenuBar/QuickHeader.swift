import SathiCore
import SwiftUI

struct QuickHeader: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack {
            Text(verbatim: Copywriter.quickPanelTitle)
                .font(Typography.cardTitle)
                .foregroundStyle(Night.text)
            Spacer(minLength: 0)
            Text(verbatim: Copywriter.quickPanelClock(e.now, calendar: e.calendar))
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
        }
    }
}
