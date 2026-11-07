import SathiCore
import SwiftUI

struct BreathFrame: View {
    let style: BreathingStyle
    let session: Session
    let date: Date
    let reduceMotion: Bool

    var body: some View {
        let m = UIMetrics.self
        let elapsed = max(0, session.elapsed(at: date))
        let step = BreathingPattern.step(style, at: elapsed)
        let tint = BreathMood.tint(style, elapsed: elapsed)
        VStack(spacing: 0) {
            ZStack {
                BreathRing(progress: BreathMotion.progress(session: session, at: date), tint: tint)
                BreathOrb(
                    open: BreathMotion.openness(style, elapsed: elapsed, reduceMotion: reduceMotion),
                    t: reduceMotion ? 0 : elapsed,
                    tint: tint,
                    ripples: reduceMotion ? [] : BreathMotion.ripples(style, elapsed: elapsed)
                )
            }
            .frame(width: m.breathStage, height: m.breathStage)
            .padding(.top, m.breathStageTop)
            .padding(.bottom, m.breathStageBottom)
            Text(Copywriter.breathCount(max(1, Int(step.remaining.rounded(.up))), step.phase))
                .font(BreathFont.font(.regular, size: m.fontBreathCount))
                .tracking(m.breathCountTracking)
                .monospacedDigit()
                .foregroundStyle(Night.muted)
            Text(Copywriter.breathLabel(step.phase))
                .font(BreathFont.font(.light, size: m.fontBreathPhase))
                .tracking(m.breathPhaseTracking)
                .foregroundStyle(RGB(hex: NightHex.text).mix(tint.main, m.breathPhaseTint).color())
            Text(Copywriter.breathLeft(max(0, session.left(at: date))))
                .font(BreathFont.font(.regular, size: m.fontBreathLeft))
                .tracking(m.breathLeftTracking)
                .monospacedDigit()
                .foregroundStyle(Night.muted)
                .padding(.top, m.breathLeftTop)
        }
    }
}
