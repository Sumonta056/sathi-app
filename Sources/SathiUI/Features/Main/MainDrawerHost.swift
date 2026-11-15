import SwiftUI

struct MainDrawerItem {
    let view: AnyView
}

struct MainDrawerKey: PreferenceKey {
    static let defaultValue: MainDrawerItem? = nil

    static func reduce(value: inout MainDrawerItem?, nextValue: () -> MainDrawerItem?) {
        value = nextValue() ?? value
    }
}

extension View {
    func mainDrawerHost() -> some View {
        overlayPreferenceValue(MainDrawerKey.self) { $0?.view }
    }
}
