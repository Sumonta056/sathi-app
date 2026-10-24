import SathiCore

enum ShakeSound {
    static func sound(for id: HabitID) -> SoundName? {
        switch id {
        case .water: .tink
        case .reading: nil
        case .meditation: nil
        }
    }
}
