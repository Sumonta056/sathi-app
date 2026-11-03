import SathiCore
import SwiftUI

struct QuickAddPopup: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        QuickAddForm { e.closeQuickAdd() }
            .modifier(CornerCard(width: UIMetrics.quickAddWidth, border: Night.quickBorder))
            .onExitCommand { e.closeQuickAdd() }
    }
}
