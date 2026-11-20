import CoreGraphics
import Foundation

extension UIMetrics {
    static let todoHoldSeconds: TimeInterval = 1.0
    static let todoFoldSeconds: TimeInterval = 0.26
    static let todoPopSeconds: TimeInterval = 0.34
    static let todoPopPeak: CGFloat = 0.22
    static let todoRingSeconds: TimeInterval = 0.48
    static let todoRingGrow: CGFloat = 1.1
    static let todoRingOpacity: Double = 0.7
    static let todoCheckSeconds: TimeInterval = 0.22
    static let todoCheckDelay: TimeInterval = 0.09
    static let todoCheckWidth: CGFloat = 2.6
    static let todoStrikeSeconds: TimeInterval = 0.3
    static let todoStrikeDelay: TimeInterval = 0.14
    static let todoStrikeThickness: CGFloat = 1.5
    static let todoStrikeLine: CGFloat = 0.55
    static let todoFillSeconds: TimeInterval = 0.18
    static let todoFadeSeconds: TimeInterval = 0.2
    static let todoCheckStart = CGPoint(x: 0.27, y: 0.53)
    static let todoCheckElbow = CGPoint(x: 0.43, y: 0.68)
    static let todoCheckEnd = CGPoint(x: 0.74, y: 0.34)
}
