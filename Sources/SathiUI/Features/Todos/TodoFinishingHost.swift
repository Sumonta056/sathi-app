import SathiCore
import SwiftUI

struct TodoFinishingHost<Content: View>: View {
    let write: (Engine, TodoFinishing) -> (String) -> Void
    @ViewBuilder let content: Content
    @EnvironmentObject var e: Engine
    @StateObject private var finishing = TodoFinishing(write: { _ in })

    var body: some View {
        content
            .environmentObject(finishing)
            .onAppear { finishing.bind(write(e, finishing)) }
            .onReceive(e.$todoSnapshot) { finishing.settle(open: Set($0.open.map(\.id))) }
            .onDisappear { finishing.flush() }
    }
}

extension View {
    func todoFinishing(write: @escaping (Engine, TodoFinishing) -> (String) -> Void) -> some View {
        TodoFinishingHost(write: write) { self }
    }
}
