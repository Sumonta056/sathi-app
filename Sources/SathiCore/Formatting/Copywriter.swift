import Foundation

package enum Copywriter {
    package static func pick(_ id: HabitID, _ level: Level, name: String) -> Copy {
        let options = choices(id, level, name: displayName(name))
        let o = options.randomElement() ?? options[0]
        return Copy(title: o.0, body: o.1)
    }

    package static func celebrationTitle(_ id: HabitID) -> String {
        let titles: [String] = switch id {
        case .water: ["Ahh, that's better.", "Fota is happy again.", "Refilled."]
        case .reading: ["Chapter done.", "Boi is proud of you.", "Nice reading."]
        case .meditation: ["Calm and clear.", "Shanti feels lighter.", "Nicely breathed."]
        }
        return titles.randomElement() ?? titles[0]
    }

    package static func displayName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "friend" : name
    }

    package static func greeting(at date: Date, name: String, calendar: Calendar) -> String {
        let hour = calendar.component(.hour, from: date)
        let part = switch hour {
        case Limits.morningStartHour ..< Limits.afternoonStartHour: "morning"
        case Limits.afternoonStartHour ..< Limits.eveningStartHour: "afternoon"
        default: "evening"
        }
        return "Good \(part), \(displayName(name))"
    }

    private static func choices(_ id: HabitID, _ level: Level, name n: String) -> [(String, String)] {
        switch (id, level) {
        case (.water, .nudge):
            return [
                ("Glass time, \(n).", "A few sips or a full glass, both count. Just tell me roughly."),
                ("Pani break!", "Your code can wait 30 seconds. I can't."),
                ("Psst. I'm getting dry.", "Grab your glass or your bottle and take a few sips.")
            ]
        case (.water, .persist):
            return [
                ("Still waiting, \(n).", "I'll sit right here on top of everything until you drink."),
                ("Ek glass pani, please.", "There is no close button. I checked."),
                ("I'm still thirsty.", "You snoozed me. I came back. That's how this works.")
            ]
        case (.reading, .nudge):
            return [
                ("Reading time, \(n).", "One chapter. I'll keep the Mac quiet while you read."),
                ("Boi misses you.", "We stopped mid-chapter last time. Let's pick it up."),
                ("Book o'clock.", "Just you and the book for a few minutes.")
            ]
        case (.reading, .persist):
            return [
                ("Still here, \(n).", "I'll stay on top until you start the timer."),
                ("Ek chapter, please.", "Your screen can wait. The story can't."),
                ("I'm not going away.", "Start the timer and I'll go quiet. Promise.")
            ]
        case (.meditation, .nudge):
            return [
                ("Breathe with me, \(n).", "A few slow breaths. Your screen will still be here after."),
                ("Shanti time.", "Sit back, drop your shoulders, and follow my breath.")
            ]
        case (.meditation, .persist):
            return [
                ("Still here, \(n).", "Just a few minutes of breathing. I'll wait."),
                ("One calm moment, please.", "Start the session and let everything else go quiet.")
            ]
        }
    }
}
