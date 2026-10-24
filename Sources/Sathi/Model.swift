import Foundation

enum HabitID: String, Codable, CaseIterable, Identifiable {
    case water, reading
    var id: String { rawValue }
    var name: String { self == .water ? "Water" : "Reading" }
    var buddy: String { self == .water ? "Fota" : "Boi" }
}

enum Strictness: String, Codable, CaseIterable, Identifiable {
    case friendly, persistent, strict
    var id: String { rawValue }
    var title: String {
        switch self {
        case .friendly: return "Friendly"
        case .persistent: return "Persistent"
        case .strict: return "Strict"
        }
    }
    var detail: String {
        switch self {
        case .friendly: return "Pops up again after each snooze."
        case .persistent: return "After one snooze it stays on top, shakes, and has no close button."
        case .strict: return "Stays on top after one snooze. After two snoozes it locks the screen until you hold to confirm."
        }
    }
}

enum Container: String, Codable, CaseIterable {
    case glass, bottle
}

struct Prefs: Codable, Equatable {
    var name = "Mridul"

    var waterEnabled = true
    var waterIntervalMinutes = 120
    var waterStartMinutes = 9 * 60 + 30
    var waterEndMinutes = 18 * 60 + 30
    var waterStrictness: Strictness = .strict
    var defaultContainer: Container = .glass
    var bottleSizeGlasses: Double = 3
    var dailyGoalGlasses: Double = 8

    var readingEnabled = true
    var readingTimeMinutes = 22 * 60
    var readingSessionMinutes = 15
    var readingStrictness: Strictness = .persistent

    var snoozeMinutes = 5
    var ignoreMinutes = 5
    var soundOn = true

    /// Changes to these fields move the schedule.
    var scheduleKey: String {
        "\(waterEnabled)-\(waterIntervalMinutes)-\(waterStartMinutes)-\(waterEndMinutes)-\(readingEnabled)-\(readingTimeMinutes)-\(readingSessionMinutes)"
    }
}

struct DrinkEntry: Codable {
    var date: Date
    var glasses: Double
}

struct ReadEntry: Codable {
    var date: Date
    var minutes: Int
}

struct Persisted: Codable {
    var prefs = Prefs()
    var drinks: [DrinkEntry] = []
    var reads: [ReadEntry] = []
    var bottleLevel: Double = 1
    var lastWaterDone: Date?
    var streakReset: [String: Date] = [:]
}

enum Fmt {
    /// "1½" style count of glasses.
    static func count(_ x: Double) -> String {
        let q = (x * 4).rounded() / 4
        let whole = Int(q)
        let f = q - Double(whole)
        let frac = f == 0.25 ? "¼" : f == 0.5 ? "½" : f == 0.75 ? "¾" : ""
        if whole == 0 { return frac.isEmpty ? "0" : frac }
        return "\(whole)\(frac)"
    }

    static func glasses(_ x: Double) -> String {
        let q = (x * 4).rounded() / 4
        return count(x) + (q <= 1 ? " glass" : " glasses")
    }

    static func short(_ t: TimeInterval) -> String {
        if t <= 0 { return "now" }
        if t < 60 { return "<1m" }
        let m = Int(t / 60)
        let h = m / 60
        return h > 0 ? "\(h)h \(m % 60)m" : "\(m)m"
    }

    static func clock(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded(.up)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func timeOfDay(_ minutes: Int) -> String {
        let cal = Calendar.current
        let d = cal.date(byAdding: .minute, value: minutes, to: cal.startOfDay(for: Date())) ?? Date()
        return d.formatted(date: .omitted, time: .shortened)
    }
}

enum Copywriter {
    static func pick(_ id: HabitID, _ level: Level, name: String) -> Copy {
        let n = name.trimmingCharacters(in: .whitespaces).isEmpty ? "friend" : name
        let options: [(String, String)]
        switch (id, level) {
        case (.water, .nudge):
            options = [
                ("Glass time, \(n).", "A few sips or a full glass, both count. Just tell me roughly."),
                ("Pani break!", "Your code can wait 30 seconds. I can't."),
                ("Psst. I'm getting dry.", "Grab your glass or your bottle and take a few sips."),
            ]
        case (.water, .persist):
            options = [
                ("Still waiting, \(n).", "I'll sit right here on top of everything until you drink."),
                ("Ek glass pani, please.", "There is no close button. I checked."),
                ("I'm still thirsty.", "You snoozed me. I came back. That's how this works."),
            ]
        case (.reading, .nudge):
            options = [
                ("Reading time, \(n).", "One chapter. I'll keep the Mac quiet while you read."),
                ("Boi misses you.", "We stopped mid-chapter last time. Let's pick it up."),
                ("Book o'clock.", "Just you and the book for a few minutes."),
            ]
        case (.reading, .persist):
            options = [
                ("Still here, \(n).", "I'll stay on top until you start the timer."),
                ("Ek chapter, please.", "Your screen can wait. The story can't."),
                ("I'm not going away.", "Start the timer and I'll go quiet. Promise."),
            ]
        }
        let o = options.randomElement() ?? options[0]
        return Copy(title: o.0, body: o.1)
    }
}
