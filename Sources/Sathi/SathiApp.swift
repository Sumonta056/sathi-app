import SathiUI
import SwiftUI

@main
struct SathiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuPanel().environmentObject(AppEnvironment.engine)
        } label: {
            StatusLabel(status: AppEnvironment.engine.status)
        }
        .menuBarExtraStyle(.window)
    }
}
