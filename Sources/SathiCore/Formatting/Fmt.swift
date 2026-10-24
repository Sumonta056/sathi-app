import Foundation

package enum Fmt {
    package static func roundToGlassStep(_ x: Double) -> Double {
        (x / Limits.glassStep).rounded() * Limits.glassStep
    }

    package static func count(_ x: Double) -> String {
        let q = roundToGlassStep(x)
        let whole = Int(q)
        let f = q - Double(whole)
        let frac = f == 0.25 ? "¼" : f == 0.5 ? "½" : f == 0.75 ? "¾" : ""
        if whole == 0 { return frac.isEmpty ? "0" : frac }
        return "\(whole)\(frac)"
    }

    package static func glasses(_ x: Double) -> String {
        count(x) + (roundToGlassStep(x) <= 1 ? " glass" : " glasses")
    }

    package static func short(_ t: TimeInterval) -> String {
        if t <= 0 { return "now" }
        if t < Timing.minute { return "<1m" }
        let m = Int(t / Timing.minute)
        let h = m / 60
        return h > 0 ? "\(h)h \(m % 60)m" : "\(m)m"
    }

    package static func clock(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded(.up)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    package static func timeOfDay(_ minutes: Int, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: Date())
        let d = calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
        return d.formatted(date: .omitted, time: .shortened)
    }

    package static func interval(minutes m: Int) -> String {
        if m % 60 == 0 { return m == 60 ? "1 hour" : "\(m / 60) hours" }
        return m > 60 ? "\(m / 60) h \(m % 60) min" : "\(m) min"
    }
}
