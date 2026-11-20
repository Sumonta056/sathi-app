import SathiCore
import SwiftUI

struct TodoFinishingHost<Content: View>: View {
    let write: (Engine) -> (String) -> Void
    @ViewBuilder let content: Content
    @EnvironmentObject var e: Engine
    @StateObject private var finishing = TodoFinishing(write: { _ in })

    var body: some View {
        content
            .environmentObject(finishing)
            .onAppear { finishing.bind(write(e)) }
            .onReceive(e.$todoSnapshot) { _ in finishing.settle() }
            .onDisappear { finishing.flush() }
    }
}

extension View {
    func todoFinishing(write: @escaping (Engine) -> (String) -> Void) -> some View {
        TodoFinishingHost(write: write) { self }
    }
}
