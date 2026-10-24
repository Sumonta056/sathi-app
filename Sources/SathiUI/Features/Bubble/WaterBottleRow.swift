import SathiCore
import SwiftUI

struct WaterBottleRow: View {
    @EnvironmentObject var e: Engine

    @State private var bottleNow: Double

    init(bottleLevel: Double) {
        _bottleNow = State(initialValue: bottleLevel)
    }

    private var drunk: Double { (e.data.live.bottleLevel - bottleNow) * e.data.prefs.water.bottleSizeGlasses }
    private var canLog: Bool { drunk >= Limits.minimumBottleDrink }

    var body: some View {
        HStack(spacing: UIMetrics.bottleRowSpacing) {
            BottleView(was: e.data.live.bottleLevel, now: $bottleNow, ink: .night)
                .frame(width: UIMetrics.bottleSize.width, height: UIMetrics.bottleSize.height)
            VStack(alignment: .leading, spacing: UIMetrics.chipSpacing) {
                Text("Drag the line to where your water is now.")
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text(canLog ? "About \(Fmt.glasses(drunk))" : "Drag down to log")
                    .font(Typography.heroTitle)
                    .foregroundStyle(Night.water)
                HStack(spacing: UIMetrics.chipSpacing) {
                    Button("Log it") { e.logBottle(newLevel: bottleNow) }
                        .buttonStyle(AccentButton(accent: Night.water, height: UIMetrics.thanksButtonHeight))
                        .disabled(!canLog)
                        .opacity(canLog ? 1 : UIMetrics.logDisabledOpacity)
                    Button("I refilled it") {
                        e.refillBottle()
                        bottleNow = 1
                    }
                    .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.thanksButtonHeight))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
