import SwiftUI

struct MainDrawer<Content: View>: View {
    let close: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .trailing) {
            MainDim(close: close)
            content()
                .frame(width: UIMetrics.activitiesEditWidth)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(Night.bg)
                .overlay(alignment: .leading) { Rectangle().fill(Night.divider).frame(width: UIMetrics.dividerHeight) }
        }
        .accessibilityIdentifier(MainLayout.drawerIdentifier)
    }
}

struct MainDim: View {
    let close: () -> Void

    var body: some View {
        ZStack {
            Night.sidebar.opacity(UIMetrics.mainDrawerDimOpacity)
                .contentShape(Rectangle())
                .onTapGesture(perform: close)
            Button(action: close) { EmptyView() }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }
}
