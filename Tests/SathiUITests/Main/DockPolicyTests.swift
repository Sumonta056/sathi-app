import AppKit
@testable import SathiUI
import Testing

@Suite("Dock policy")
struct DockPolicyTests {
    @Test func openMainWindowShowsTheDockIcon() {
        #expect(DockPolicy.policy(mainWindowOpen: true) == .regular)
    }

    @Test func closedMainWindowKeepsSathiInTheMenuBarOnly() {
        #expect(DockPolicy.policy(mainWindowOpen: false) == .accessory)
    }
}
