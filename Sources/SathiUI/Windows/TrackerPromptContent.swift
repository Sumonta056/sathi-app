import SathiCore
import SwiftUI

struct TrackerPromptContent: View {
    let state: TrackerPromptState
    let model: ActivityPromptModel

    var body: some View {
        ActivityPromptView(state: state, model: model)
            .id(ObjectIdentifier(model))
    }
}
