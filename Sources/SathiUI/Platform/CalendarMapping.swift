import SathiCore

package enum CalendarMapping {
    package static func access(notDetermined: Bool, granted: Bool) -> CalendarAccess {
        if notDetermined { return .notAsked }
        return granted ? .allowed : .denied
    }

    package static func hex(red: Double, green: Double, blue: Double) -> UInt32 {
        func byte(_ value: Double) -> UInt32 {
            UInt32((min(max(value, 0), 1) * 255).rounded())
        }
        return byte(red) << 16 | byte(green) << 8 | byte(blue)
    }

    package static func sorted(_ choices: [CalendarChoice]) -> [CalendarChoice] {
        choices.sorted {
            let byAccount = $0.account.localizedCompare($1.account)
            if byAccount != .orderedSame { return byAccount == .orderedAscending }
            return $0.title.localizedCompare($1.title) == .orderedAscending
        }
    }
}
