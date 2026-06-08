import SwiftUI

struct VibriseScreenBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                DesignTokens.Colors.backgroundTop,
                DesignTokens.Colors.backgroundBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
