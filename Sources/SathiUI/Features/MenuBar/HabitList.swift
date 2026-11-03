import SathiCore
import SwiftUI

struct HabitList: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let ids = HabitID.allCases.filter { e.enabled($0) }
        if !ids.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(ids.enumerated()), id: \.element) { index, id in
                    if index > 0 {
                        Rectangle()
                            .fill(Night.divider)
                            .frame(height: UIMetrics.dividerHeight)
                    }
                    HabitCard(id: id)
                }
            }
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
