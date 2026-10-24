import SathiCore
import SwiftUI

struct WaterLogSection: View {
    @EnvironmentObject var e: Engine

    @State private var container: Container = .glass
    @State private var bottleNow: Double = 1

    private var drunk: Double { (e.data.live.bottleLevel - bottleNow) * e.data.prefs.water.bottleSizeGlasses }
    private var canLogBottle: Bool { drunk >= Limits.minimumBottleDrink }

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $container) {
                Text("Glass").tag(Container.glass)
                Text("Sip bottle").tag(Container.bottle)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if container == .glass {
                HStack(spacing: 8) {
                    glassButton(0.25, "A few sips")
                    glassButton(0.5, "Half")
                    glassButton(1, "Full glass")
                }
                .frame(maxHeight: .infinity)
            } else {
                bottleRow
            }
        }
        .frame(height: 196)
        .onAppear {
            container = e.data.prefs.water.container
            bottleNow = e.data.live.bottleLevel
        }
    }

    private func glassButton(_ glasses: Double, _ label: String) -> some View {
        Button {
            e.logWater(glasses)
        } label: {
            VStack(spacing: 6) {
                GlassIcon(fill: glasses).frame(width: 30, height: 36)
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(Palette.waterDeep)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.waterDeep.opacity(0.2), lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bottleRow: some View {
        HStack(spacing: 16) {
            BottleView(was: e.data.live.bottleLevel, now: $bottleNow)
                .frame(width: 76, height: 150)
            VStack(alignment: .leading, spacing: 8) {
                Text("Drag the line to where your water is now.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(canLogBottle ? "About \(Fmt.glasses(drunk))" : "Drag down to log")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.waterDeep)
                Button("Log it") { e.logBottle(newLevel: bottleNow) }
                    .buttonStyle(PillButton(kind: .primary, height: 38))
                    .disabled(!canLogBottle)
                    .opacity(canLogBottle ? 1 : 0.45)
                Button("I refilled it") {
                    e.refillBottle()
                    bottleNow = 1
                }
                .buttonStyle(PillButton(kind: .ghost, height: 38))
            }
        }
    }
}
