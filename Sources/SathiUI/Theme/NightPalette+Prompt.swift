import SathiCore
import SwiftUI

extension Night {
    static let promptAsk = tracker
    static let promptShortcut = Color(hex: 0xA99CF5)
    static let promptEnds = Color(hex: 0xFFC94A)
    static let promptBack = Color(hex: 0x5FD39A)
    static let promptEvent = trackerEvent
    static let promptHeader = trackerInset
    static let promptCard = Color(hex: 0x1A2233)
    static let promptCardLine = Color(hex: 0x263049)
    static let promptBoxLine = Color(hex: 0x2C3650)
    static let promptBox = trackerWell
    static let promptPane = Color(hex: 0x131A28)
    static let promptCardFilled = trackerFill
    static let promptSecondary = Color(hex: 0x9AA6BF)
    static let promptDim = Color(hex: 0x4A5570)
    static let promptBackLine = promptBack.opacity(0.4)

    static func reason(_ r: PromptReason) -> Color {
        switch r {
        case .ask: promptAsk
        case .shortcut: promptShortcut
        case .ends: promptEnds
        case .back: promptBack
        case .event: promptEvent
        }
    }
}
