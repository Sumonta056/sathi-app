import Combine
import SathiCore
import SwiftUI

struct BubbleView: View {
    @EnvironmentObject var e: Engine
    let id: HabitID
    let level: Level

    @State private var shakes: CGFloat = 0
    private let shakeTimer = Timer.publish(every: UIMetrics.shakeInterval, on: .main, in: .common).autoconnect()

    private var accent: Color { Palette.accent(id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            switch id {
            case .water: WaterLogSection()
            case .reading: ReadingInfoCard()
            }
            actions
            if level == .persist { warn }
            IgnoreBar(accent: accent)
        }
        .padding(18)
        .frame(width: UIMetrics.bubbleWidth)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(level == .persist ? accent : Color.black.opacity(0.08), lineWidth: level == .persist ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 10)
        .modifier(Shake(amount: shakes))
        .padding(UIMetrics.bubbleShadowPadding)
        .foregroundStyle(Palette.ink)
        .onReceive(shakeTimer) { _ in
            guard level == .persist else { return }
            withAnimation(.linear(duration: UIMetrics.shakeDuration)) { shakes += 1 }
            e.play(.tink)
        }
    }

    private var eyebrow: String {
        let time = e.now.formatted(date: .omitted, time: .shortened)
        if level == .persist {
            return "STILL WAITING · SNOOZED \(e.state(id).snoozes)× · \(time)"
        }
        return "\(id.name.uppercased()) · \(time)"
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            BuddyView(kind: id.kind, mood: .thirsty, level: 0.06)
                .frame(width: 78, height: 96)
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Palette.deep(id))
                Text(e.copy.title)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Text(e.copy.body)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            switch id {
            case .water:
                EmptyView()
            case .reading:
                Button("Start \(e.data.prefs.readingSessionMinutes)-min timer") { e.startReading() }
                    .buttonStyle(PillButton(kind: .primary))
                    .layoutPriority(1)
            }
            Button(e.snoozeLabel(id)) { e.snooze() }
                .buttonStyle(PillButton(kind: .ghost))
        }
    }

    private var warn: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill").foregroundStyle(Palette.deep(id))
            Text(e.warnText(id)).font(.system(size: 12.5)).foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.14)))
    }
}
