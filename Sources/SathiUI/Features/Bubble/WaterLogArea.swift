import SathiCore
import SwiftUI

struct WaterLogArea: View {
    @EnvironmentObject var e: Engine
    let container: Container

    var body: some View {
        area.frame(height: UIMetrics.waterLogHeight)
    }

    @ViewBuilder
    private var area: some View {
        switch container {
        case .glass:
            HStack(spacing: UIMetrics.amountCardSpacing) {
                AmountCard(amount: 0.25, label: "A few sips") { e.logWater(0.25) }
                AmountCard(amount: 0.5, label: "Half") { e.logWater(0.5) }
                AmountCard(amount: 1, label: "Full glass", level: UIMetrics.fullGlassLevel) { e.logWater(1) }
            }
        case .bottle:
            WaterBottleRow(bottleLevel: e.data.live.bottleLevel)
        }
    }
}
