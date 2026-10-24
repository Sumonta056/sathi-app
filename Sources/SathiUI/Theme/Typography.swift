import SwiftUI

enum Typography {
    static let title = rounded(UIMetrics.fontTitle, .black)
    static let heroTitle = rounded(UIMetrics.fontHeroTitle, .black)
    static let rowLabel = rounded(UIMetrics.fontRowLabel, .heavy)
    static let hint = rounded(UIMetrics.fontHint, .semibold)
    static let chip = rounded(UIMetrics.fontChip, .heavy)
    static let sectionLabel = rounded(UIMetrics.fontSectionLabel, .black)
    static let eyebrow = rounded(UIMetrics.fontEyebrow, .black)
    static let badge = rounded(UIMetrics.fontBadge, .black)
    static let bigNumber = rounded(UIMetrics.fontBigNumber, .black)
    static let stepperSymbol = rounded(UIMetrics.fontStepperSymbol, .heavy)
    static let cardTitle = rounded(UIMetrics.fontCardTitle, .black)
    static let pill = rounded(UIMetrics.fontPill, .heavy)
    static let bubbleTitle = rounded(UIMetrics.fontBubbleTitle, .black)
    static let thanksTitle = rounded(UIMetrics.fontThanksTitle, .black)
    static let amountLabel = rounded(UIMetrics.fontAmountLabel, .black)
    static let cornerTitle = rounded(UIMetrics.fontCornerTitle, .black)
    static let pillTime = rounded(UIMetrics.fontPillTime, .black).monospacedDigit()
    static let pillHint = rounded(UIMetrics.fontPillHint, .semibold)
    static let breathPhase = rounded(UIMetrics.fontBreathPhase, .black)

    private static func rounded(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
