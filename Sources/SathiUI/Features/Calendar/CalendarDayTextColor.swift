import Foundation

enum CalendarDayTextColor {
    static func hex(_ hex: UInt32) -> UInt32 {
        let c = RGB(hex: hex)
        let w = UIMetrics.calendarDayLuma
        guard w.r * c.r + w.g * c.g + w.b * c.b < UIMetrics.calendarDayTextLumaMin else { return hex }
        let lifted = c.mix(RGB(hex: NightHex.text), UIMetrics.calendarDayTextLift)
        return [lifted.r, lifted.g, lifted.b].reduce(UInt32(0)) { ($0 << 8) | UInt32(($1 * 255).rounded()) }
    }
}
