import SathiCore
import SwiftUI

struct TrackerPromptContent: View {
    let state: TrackerPromptState

    var body: some View {
        ActivityPromptView(state: state)
    }
}
