import SwiftUI

extension UIMetrics {
    static let breathStage: CGFloat = 236
    static let breathRingRadius: CGFloat = 114
    static let breathRingWidth: CGFloat = 1
    static let breathTrackOpacity: Double = 0.8
    static let breathArcOpacity: Double = 0.85
    static let breathTicks = 5
    static let breathTickInner: CGFloat = 110
    static let breathTickOuter: CGFloat = 117
    static let breathDotRadius: CGFloat = 2.5
    static let breathStageTop: CGFloat = 14
    static let breathStageBottom: CGFloat = 10

    static let breathCore: CGFloat = 104
    static let breathCoreCenter = UnitPoint(x: 0.4, y: 0.35)
    static let breathCoreReach: CGFloat = 0.885
    static let breathCoreLightOpacity: Double = 0.9
    static let breathCoreMidOpacity: Double = 0.35
    static let breathCoreMidStop: CGFloat = 0.6

    static let breathBlobs = 3
    static let breathBlob: CGFloat = 150
    static let breathBlobBlur: CGFloat = 12
    static let breathBlobDrift: Double = 8
    static let breathBlobDriftRateY: Double = 0.8
    static let breathBlobSwing: Double = 0.12
    static let breathBlobRadiusRate: Double = 2
    static let breathBlobRadiusRateY: Double = 1.6
    static let breathBlobCornerStep: Double = 1.7
    static let breathBlobCornerStepY: Double = 1.3
    static let breathBlobSpin: Double = 8
    static let breathBlobAngleStep: Double = 120
    static let breathBlobFrequency: Double = 0.18
    static let breathBlobFrequencyStep: Double = 0.07
    static let breathBlobPhaseStep: Double = 2.1
    static let breathBlobScaleStep: Double = 0.06
    static let breathBlobCenter = UnitPoint(x: 0.5, y: 0.45)
    static let breathBlobReach: CGFloat = 0.74
    static let breathBlobOpacity: Double = 0.85
    static let breathBlobStop: CGFloat = 0.72

    static let breathOrbScale: ClosedRange<Double> = 0.72 ... 1
    static let breathCoreScale: ClosedRange<Double> = 0.82 ... 1
    static let breathFaceScale: ClosedRange<Double> = 0.84 ... 1.05
    static let breathFaceSize: CGFloat = 76

    static let breathRipples = 3
    static let breathRippleGap: Double = 1.1
    static let breathRippleSpan: Double = 3.8
    static let breathRippleFrom: CGFloat = 70
    static let breathRippleTo: CGFloat = 108
    static let breathRippleWidth: CGFloat = 5
    static let breathRippleBlur: CGFloat = 1.5
    static let breathRipplePeak: Double = 0.32
    static let breathRippleFade: Double = 0.4

    static let breathMoodBlend: Double = 1.4
    static let breathReducedOpenness: Double = 0.85
    static let breathReducedInterval: Double = 0.25

    static let fontBreathEyebrow: CGFloat = 11
    static let breathEyebrowTracking: CGFloat = 2.2
    static let fontBreathCount: CGFloat = 12
    static let breathCountTracking: CGFloat = 2.4
    static let fontBreathPhase: CGFloat = 34
    static let breathPhaseTracking: CGFloat = 0.68
    static let fontBreathLeft: CGFloat = 13
    static let breathLeftTracking: CGFloat = 0.78
    static let breathLeftTop: CGFloat = 4
    static let fontBreathButton: CGFloat = 13

    static let breathButtonHeight: CGFloat = 30
    static let breathButtonPadding: CGFloat = 14
    static let breathButtonGap: CGFloat = 18
    static let breathButtonsTop: CGFloat = 24
    static let breathSeparator = CGSize(width: 1, height: 14)

    static let breathCardTop: CGFloat = 26
    static let breathCardBottom: CGFloat = 22
}

extension UIMetrics {
    static let breathInhaleMain: Double = 0.45
    static let breathHoldMain: Double = 0.30
    static let breathHoldAccent: Double = 0.35
    static let breathExhaleMain: Double = 0.22
    static let breathRestMain: Double = 0.50
    static let breathRestAccent: Double = 0.3
    static let breathCoreLight: Double = 0.4
    static let breathRippleLight: Double = 0.2
    static let breathPhaseTint: Double = 0.25
    static let breathRingLight: Double = 0.4
    static let breathBlobAccentMix: Double = 0.25
    static let breathBlobSproutMix: Double = 0.55
}
