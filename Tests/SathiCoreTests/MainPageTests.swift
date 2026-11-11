import SathiCore
import Testing

@Suite("Main page")
struct MainPageTests {
    @Test func settingsPagesFollowTheSidebarOrder() {
        #expect(SettingsPage.all == [
            .general, .habit(.water), .habit(.reading), .habit(.meditation), .habit(.gym),
            .quickReminders, .tracker, .timeBlocks, .sound
        ])
    }
}
