import SathiCore
import SwiftUI

struct MenuCards: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        CappedHeight(maxHeight: UIMetrics.menuCardsMaxHeight) {
            ScrollView {
                VStack(alignment: .leading, spacing: UIMetrics.menuSpacing) {
                    ForEach(HabitID.allCases.filter { e.enabled($0) }) { id in
                        HabitCard(id: id)
                    }
                    ForEach(HabitID.allCases.filter { !e.enabled($0) }) { id in
                        SleepingRow(id: id)
                    }
                    QuickListCard()
                    TimeBlockCard()
                }
            }
        }
    }
}
