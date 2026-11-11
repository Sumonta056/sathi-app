import SathiCore
import SwiftUI

struct PromptKey: ViewModifier {
    let shortcut: KeyboardShortcut?

    func body(content: Content) -> some View {
        if let shortcut {
            content.keyboardShortcut(shortcut)
        } else {
            content
        }
    }

    static let start = PromptKey(shortcut: .defaultAction)
    static let skip = PromptKey(shortcut: .cancelAction)

    static func recent(_ index: Int) -> PromptKey {
        guard index < UIMetrics.recentKeys else { return PromptKey(shortcut: nil) }
        return PromptKey(shortcut: KeyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command))
    }
}
