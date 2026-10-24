import SathiCore
import SwiftUI

struct ReadingTimerPill: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(spacing: UIMetrics.pillSpacing) {
            PillRing(start: e.sessionStart, end: e.sessionEnd, now: e.now)
            VStack(alignment: .leading, spacing: UIMetrics.pillTextSpacing) {
                PillCountdown(now: e.now, end: e.sessionEnd)
                PillCaption()
            }
            Button("Stop") { e.stopSession() }
                .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.pillButtonHeight))
        }
        .padding(UIMetrics.timerPillPadding)
        .background(Capsule().fill(Night.card))
        .overlay(Capsule().strokeBorder(Night.heroBorder(.reading), lineWidth: UIMetrics.bubbleBorder))
        .modifier(CornerShadow())
        .padding(UIMetrics.bubbleShadowPadding)
        .environment(\.colorScheme, .dark)
    }
}

private struct PillCountdown: View {
    let now: Date
    let end: Date

    var body: some View {
        HStack(spacing: 0) {
            Text(timerInterval: now ... max(now, end), countsDown: true)
            Text(" left")
        }
        .font(Typography.pillTime)
        .foregroundStyle(Night.text)
    }
}

private struct PillCaption: View {
    var body: some View {
        Text("Boi is reading with you")
            .font(Typography.pillHint)
            .foregroundStyle(Night.muted)
    }
}

struct PillRing: View {
    let start: Date
    let end: Date
    let now: Date

    static func fraction(start: Date, end: Date, now: Date) -> Double {
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1, max(0, end.timeIntervalSince(now) / total))
    }

    var body: some View {
        ZStack {
            Circle().stroke(Night.fieldBorder, lineWidth: UIMetrics.pillRingLine)
            Circle()
                .trim(from: 0, to: Self.fraction(start: start, end: end, now: now))
                .stroke(Night.reading, style: StrokeStyle(lineWidth: UIMetrics.pillRingLine, lineCap: .round))
                .rotationEffect(.degrees(UIMetrics.ringStartAngle))
        }
        .frame(width: UIMetrics.pillRingSize, height: UIMetrics.pillRingSize)
    }
}
