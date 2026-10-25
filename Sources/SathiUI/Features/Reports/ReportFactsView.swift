import SathiCore
import SwiftUI

struct ReportFactsView: View {
    let facts: [ReportFact]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
            ForEach(facts) { fact in
                HStack {
                    Text(verbatim: fact.label)
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                    Spacer(minLength: 0)
                    Text(verbatim: fact.value)
                        .font(Typography.rowLabel)
                        .foregroundStyle(Night.text)
                }
            }
        }
    }
}
