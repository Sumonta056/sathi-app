import SathiCore
import SwiftUI

struct TrackerPromptContent: View {
    let state: TrackerPromptState
    let model: ActivityPromptModel
    var visible: CGRect?
    var onDrop: () -> Void = {}

    var body: some View {
        ActivityPromptView(
            state: state, model: model,
            visibleHeight: visible?.height, visibleWidth: visible?.width, onDrop: onDrop
        )
        .id(ObjectIdentifier(model))
    }
}
