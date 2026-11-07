import SathiCore
import SwiftUI

enum BreathScale {
    case orb, core, face

    var range: ClosedRange<Double> {
        switch self {
        case .orb: UIMetrics.breathOrbScale
        case .core: UIMetrics.breathCoreScale
        case .face: UIMetrics.breathFaceScale
        }
    }
}

struct BlobState: Equatable {
    var dx: Double
    var dy: Double
    var rotation: Double
    var scale: Double
    var radii: [Double]
}

enum BreathMotion {
    static func into(_ style: BreathingStyle, elapsed: TimeInterval) -> (step: BreathStep, length: TimeInterval) {
        let step = BreathingPattern.step(style, at: elapsed)
        let length = BreathingPattern.steps(style).first { $0.0 == step.phase }?.1 ?? 0
        return (step, length)
    }

    static func openness(_ style: BreathingStyle, elapsed: TimeInterval, reduceMotion: Bool = false) -> Double {
        if reduceMotion { return UIMetrics.breathReducedOpenness }
        let (step, length) = into(style, elapsed: elapsed)
        let p = length > 0 ? min(1, max(0, 1 - step.remaining / length)) : 1
        let eased = (1 - cos(.pi * p)) / 2
        switch step.phase {
        case .inhale: return eased
        case .hold: return 1
        case .exhale: return 1 - eased
        case .rest: return 0
        }
    }

    static func scale(open: Double, _ kind: BreathScale) -> Double {
        let r = kind.range
        return r.lowerBound + (r.upperBound - r.lowerBound) * open
    }

    static func sinceInhale(_ style: BreathingStyle, elapsed: TimeInterval) -> TimeInterval? {
        let step = BreathingPattern.step(style, at: elapsed)
        switch step.phase {
        case .inhale, .hold:
            return max(0, elapsed) - Double(step.cycle) * BreathingPattern.cycleLength(style)
        case .exhale, .rest:
            return nil
        }
    }

    static func ripples(_ style: BreathingStyle, elapsed: TimeInterval) -> [Double] {
        guard let since = sinceInhale(style, elapsed: elapsed) else { return [] }
        return (0 ..< UIMetrics.breathRipples).compactMap { k in
            let t = (since - Double(k) * UIMetrics.breathRippleGap) / UIMetrics.breathRippleSpan
            return t > 0 && t < 1 ? t : nil
        }
    }

    static func blob(index j: Int, t: Double, open: Double) -> BlobState {
        let m = UIMetrics.self
        let n = Double(j)
        let f = m.breathBlobFrequency + n * m.breathBlobFrequencyStep
        let p = n * m.breathBlobPhaseStep
        let swing = m.breathBlobSwing
        let x = (0 ..< 2).map { k in 0.5 + swing * sin(t * f * m.breathBlobRadiusRate + p + Double(k) * m.breathBlobCornerStep) }
        let y = (0 ..< 2).map { k in 0.5 + swing * cos(t * f * m.breathBlobRadiusRateY + p + Double(k) * m.breathBlobCornerStepY) }
        let turn = j.isMultiple(of: 2) ? 1.0 : -1.0
        return BlobState(
            dx: m.breathBlobDrift * sin(t * f + p),
            dy: m.breathBlobDrift * cos(t * f * m.breathBlobDriftRateY + p),
            rotation: (t * m.breathBlobSpin * turn + n * m.breathBlobAngleStep).truncatingRemainder(dividingBy: 360),
            scale: scale(open: open, .orb) * (1 + n * m.breathBlobScaleStep),
            radii: x + y
        )
    }

    static func progress(session s: Session, at date: Date) -> Double {
        let total = s.end.timeIntervalSince(s.start)
        guard total > 0 else { return 1 }
        return min(1, max(0, s.elapsed(at: date) / total))
    }
}
