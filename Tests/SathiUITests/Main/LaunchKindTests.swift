import Carbon
import SathiUI
import Testing

@Suite("Launch kind")
struct LaunchKindTests {
    @Test func loginItemLaunchIsALoginItem() {
        #expect(LaunchKind.isLoginItem(propData: OSType(keyAELaunchedAsLogInItem)))
    }

    @Test func launchWithoutTheFlagIsAUserLaunch() {
        #expect(!LaunchKind.isLoginItem(propData: nil))
    }

    @Test func serviceItemLaunchIsAUserLaunch() {
        #expect(!LaunchKind.isLoginItem(propData: OSType(keyAELaunchedAsServiceItem)))
    }
}
