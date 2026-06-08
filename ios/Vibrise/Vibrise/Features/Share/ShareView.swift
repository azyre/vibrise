import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
struct ShareView: View {
    let image: UIImage
    let onClose: () -> Void

    @State private var isShowingShareSheet = false
    @State private var isSavingImage = false
    @State private var toastMessage: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var isContentVisible = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.56)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        ShareCloseButton(onClose: onClose)
                    }
                    .padding(.top, 62)
                    .padding(.horizontal, DesignTokens.Spacing.pageHorizontal)

                    Spacer(minLength: 0)

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        SharePreviewCard(image: image)
                            .frame(width: 280, height: 350.52, alignment: .topLeading)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 120)

                    actionStack
                        .padding(.top, 100)
                        .padding(.horizontal, DesignTokens.Spacing.pageHorizontal)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 8))
                }

                if let toastMessage {
                    ShareToastOverlay(message: toastMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .opacity(isContentVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.2)) {
                    isContentVisible = true
                }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ActivityView(items: [image])
        }
        .animation(.easeOut(duration: 0.22), value: toastMessage)
        .onDisappear {
            toastTask?.cancel()
        }
    }

    private var actionStack: some View {
        VStack(spacing: 16) {
            ShareActionButton(
                title: isSavingImage ? "Saving..." : "Save Image",
                systemImage: "square.and.arrow.down",
                isLoading: isSavingImage,
                action: saveImage
            )

            ShareActionButton(
                title: "Share",
                systemImage: "square.and.arrow.up",
                action: { isShowingShareSheet = true }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func saveImage() {
        guard !isSavingImage else {
            return
        }

        isSavingImage = true
        Task { @MainActor in
            defer {
                isSavingImage = false
            }

            do {
                try await PhotoLibrarySaver.save(image)
                showToast("Saved to Photos")
            } catch PhotoLibrarySaverError.permissionDenied {
                showToast("Photo access denied")
            } catch {
                showToast("Couldn't save image")
            }
        }
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message

        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(DesignTokens.Motion.toastDurationMs))
            toastMessage = nil
        }
    }
}

#Preview {
    ShareView(image: UIImage(), onClose: {})
}
#endif
