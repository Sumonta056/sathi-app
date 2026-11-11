import SathiCore
import SwiftUI

struct QuickBuddyList: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let buddies = e.todayBuddies
        VStack(spacing: 0) {
            ForEach(Array(buddies.enumerated()), id: \.element.id) { index, buddy in
                if index > 0 {
                    Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight)
                }
                QuickBuddyRow(buddy: buddy)
            }
        }
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
