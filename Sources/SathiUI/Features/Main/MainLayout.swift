import SwiftUI

struct MainLayout: Equatable {
    static let drawerIdentifier = "main.layout.drawer"
    static let floatingIdentifier = "main.layout.floating"
    static let stackedIdentifier = "main.layout.stacked"
    static let wide = MainLayout(width: .infinity)

    let isNarrow: Bool
    let drawerEdit: Bool

    init(width: CGFloat) {
        isNarrow = width < UIMetrics.mainNarrowBelow
        drawerEdit = width < UIMetrics.mainDrawerBelow
    }
}

private struct MainLayoutKey: EnvironmentKey {
    static let defaultValue = MainLayout.wide
}

extension EnvironmentValues {
    var mainLayout: MainLayout {
        get { self[MainLayoutKey.self] }
        set { self[MainLayoutKey.self] = newValue }
    }
}
