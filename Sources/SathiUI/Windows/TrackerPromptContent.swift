import SathiCore
import SwiftUI

struct TrackerPromptContent: View {
    let state: TrackerPromptState

    var body: some View {
        switch state.kind {
        case .whatNow: WhatNowPopup(state: state)
        case .center: CenterPromptView(state: state)
        case .stillOnIt: StillOnItPopup(state: state)
        case .welcomeBack: WelcomeBackView(state: state)
        case .eventAsk: EventAskPopup(state: state)
        }
    }
}
