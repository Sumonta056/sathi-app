import SwiftUI

struct LockShade: View {
    var body: some View {
        Night.sidebar.opacity(UIMetrics.lockShadeOpacity).ignoresSafeArea()
    }
}
