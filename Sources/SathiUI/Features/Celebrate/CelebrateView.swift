import SathiCore
import SwiftUI

struct CelebrateView: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        switch e.celebration.id {
        case .water: WaterThanks()
        case .reading:
            if e.usesCorner(.reading) { ReadingDoneCard() } else { LegacyCelebrate() }
        case .meditation: MeditationThanks()
        }
    }
}
