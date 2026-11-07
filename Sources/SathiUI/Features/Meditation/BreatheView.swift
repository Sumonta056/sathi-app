import SathiCore
import SwiftUI

struct BreatheView: View {
    @EnvironmentObject var e: Engine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        if let s = e.session(.meditation) {
            card(s, style: e.data.prefs.meditation.style)
        }
    }

    private func card(_ s: Session, style: BreathingStyle) -> some View {
        let m = UIMetrics.self
        let interval = reduceMotion ? m.breathReducedInterval : m.animationFrameInterval
        return VStack(spacing: 0) {
            Text(Copywriter.breathEyebrow(style))
                .font(BreathFont.font(.semibold, size: m.fontBreathEyebrow))
                .tracking(m.breathEyebrowTracking)
                .foregroundStyle(Night.muted)
            TimelineView(.animation(minimumInterval: interval, paused: !isVisible || s.isPaused)) { tl in
                BreathFrame(style: style, session: s, date: tl.date, reduceMotion: reduceMotion)
            }
            controls(paused: s.isPaused)
                .padding(.top, m.breathButtonsTop)
        }
        .modifier(CalmCard(top: m.breathCardTop, bottom: m.breathCardBottom))
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private func controls(paused: Bool) -> some View {
        let m = UIMetrics.self
        return HStack(spacing: m.breathButtonGap) {
            textButton(paused ? "Resume" : "Pause") {
                paused ? e.resumeSession(.meditation) : e.pauseSession(.meditation)
            }
            Rectangle()
                .fill(Night.border)
                .frame(width: m.breathSeparator.width, height: m.breathSeparator.height)
            textButton("Stop") { e.stopSession(.meditation) }
        }
    }

    private func textButton(_ title: String, action: @escaping () -> Void) -> some View {
        let m = UIMetrics.self
        return Button(action: action) {
            Text(title)
                .font(BreathFont.font(.medium, size: m.fontBreathButton))
                .foregroundStyle(Night.muted)
                .padding(.horizontal, m.breathButtonPadding)
                .frame(height: m.breathButtonHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
