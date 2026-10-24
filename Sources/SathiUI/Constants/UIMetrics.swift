import SwiftUI

enum UIMetrics {
    static let animationFrameInterval: Double = 1.0 / 30
    static let fadeDuration: Double = 0.25
    static let shakeInterval: TimeInterval = 4
    static let shakeDuration: Double = 0.6
    static let sessionRefresh: TimeInterval = 1
    static let ignoreBarRefresh: TimeInterval = 0.5

    static let menuWidth: CGFloat = 380
    static let bubbleWidth: CGFloat = 380
    static let bubbleShadowPadding: CGFloat = 24
    static let bubbleScreenInset = CGPoint(x: 12, y: 20)
    static let settingsSize = CGSize(width: 860, height: 620)
    static let lockHoldDistance: CGFloat = 80

    static let buddyAspect: CGFloat = 100.0 / 124.0
    static let statusIconSize = NSSize(width: 14, height: 17)
}
