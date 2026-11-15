import SathiCore
import SwiftUI

struct TrackerPromptContent: View {
    let state: TrackerPromptState
    let model: ActivityPromptModel
    var maxHeight: CGFloat?
    var onMove: (CGSize) -> Void = { _ in }

    var body: some View {
        ActivityPromptView(state: state, model: model, maxHeight: maxHeight, onMove: onMove)
            .id(ObjectIdentifier(model))
    }
}
