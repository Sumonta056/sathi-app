import SathiCore

package enum HotkeyModifiers {
    private static let command: UInt32 = 1 << 8
    private static let shift: UInt32 = 1 << 9
    private static let option: UInt32 = 1 << 11
    private static let control: UInt32 = 1 << 12

    package static func carbonFlags(_ modifiers: Set<KeyModifier>) -> UInt32 {
        modifiers.reduce(0) { flags, modifier in
            switch modifier {
            case .command: flags | command
            case .shift: flags | shift
            case .option: flags | option
            case .control: flags | control
            }
        }
    }
}
