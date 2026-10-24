import SathiCore
import SwiftUI

struct WaterBubble: View {
    @EnvironmentObject var e: Engine
    let level: Level

    @State private var picked: Container?
    @State private var shakes: CGFloat = 0

    private var container: Binding<Container> {
        Binding(get: { picked ?? e.data.prefs.water.container }, set: { picked = $0 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.bubbleSpacing) {
            WaterBubbleHeader(level: level)
            WaterLogArea(container: container.wrappedValue)
            HStack {
                ContainerSegment(selection: container)
                Spacer(minLength: 0)
                Button(e.snoozeLabel(.water)) { e.snooze() }
                    .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.snoozeHeight))
            }
            if level == .persist { warn }
            IgnoreBar(accent: Night.water, track: Night.border)
        }
        .padding(UIMetrics.bubblePadding)
        .modifier(WaterCard(alert: level == .persist))
        .modifier(Shake(amount: shakes))
        .padding(UIMetrics.bubbleShadowPadding)
        .environment(\.colorScheme, .dark)
        .task(id: level) { await shakeWhilePersisting() }
    }

    private var warn: some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            Image(systemName: "lock.fill").foregroundStyle(Night.water)
            Text(e.warnText(.water))
                .font(Typography.hint)
                .foregroundStyle(Night.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(UIMetrics.warnPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: UIMetrics.warnRadius, style: .continuous).fill(Night.heroFill(.water)))
    }

    private func shakeWhilePersisting() async {
        guard level == .persist else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(UIMetrics.shakeInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: UIMetrics.shakeDuration)) { shakes += 1 }
            if let s = ShakeSound.sound(for: .water) { e.play(s) }
        }
    }
}
