import Foundation

package enum MeditationSlot: String, Codable, CaseIterable, Sendable {
    case morning, afternoon, evening

    package var minutes: Int {
        switch self {
        case .morning: return Limits.morningSlotMinutes
        case .afternoon: return Limits.afternoonSlotMinutes
        case .evening: return Limits.eveningSlotMinutes
        }
    }
}

package enum BreathingStyle: String, Codable, CaseIterable, Sendable {
    case box, relax, even
}

package struct MeditationPrefs: Codable, Equatable, Sendable {
    package var enabled = false
    package var slots: Set<MeditationSlot> = [.morning, .evening]
    package var sessionMinutes = 5
    package var style: BreathingStyle = .box
    package var chime = true
    package var strictness: Strictness = .friendly

    package init() {}

    enum CodingKeys: String, CodingKey {
        case enabled, slots, sessionMinutes, style, chime, strictness
    }

    package var sortedSlots: [MeditationSlot] {
        MeditationSlot.allCases.filter(slots.contains)
    }
}

extension MeditationPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MeditationPrefs()
        enabled = try c.value(.enabled, or: d.enabled)
        slots = try c.knownSet(.slots, or: d.slots, keepsEmpty: true)
        sessionMinutes = try c.value(.sessionMinutes, or: d.sessionMinutes)
        style = try c.known(.style, or: d.style)
        chime = try c.value(.chime, or: d.chime)
        strictness = try c.value(.strictness, or: d.strictness)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(sortedSlots, forKey: .slots)
        try c.encode(sessionMinutes, forKey: .sessionMinutes)
        try c.encode(style, forKey: .style)
        try c.encode(chime, forKey: .chime)
        try c.encode(strictness, forKey: .strictness)
    }
}
