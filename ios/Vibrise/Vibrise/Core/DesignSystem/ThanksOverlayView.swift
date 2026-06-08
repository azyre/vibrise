import SwiftUI

struct ThanksOverlayView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            Text(message)
                .font(.custom("MavenPro-Regular", size: 72))
                .kerning(-2.88)
                .multilineTextAlignment(.center)
                .lineSpacing(0)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }
}
