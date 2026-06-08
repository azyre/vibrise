import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: RingViewModel
    @ObservedObject private var donationCoordinator: DonationCoordinator
    private let autoPresentDonationOnAppear: Bool
    private let onDismiss: (HomeBackgroundStyle, Data?) -> Void
    private let onSnooze: (HomeBackgroundStyle, Data?) -> Void
    private let onToggleFavorite: (Song) -> Void
    private let initialBackgroundStyle: HomeBackgroundStyle
    @State private var completionTask: Task<Void, Never>?
    @State private var toastTask: Task<Void, Never>?
    @State private var shareTask: Task<Void, Never>?
    #if canImport(UIKit)
    @State private var sharePreviewImage: UIImage?
    #endif
    @State private var isPreparingShare = false
    @State private var autoDonationTask: Task<Void, Never>?
    @State private var backgroundStyle: HomeBackgroundStyle
    @State private var orbSeed = UInt64.random(in: 0 ... UInt64.max)
    @State private var artworkImageData: Data?
    #if canImport(UIKit)
    @State private var artworkBackgroundImage: UIImage?
    #endif

    init(
        alarm: Alarm = .mockWeekdayMorning,
        song: Song = .mockMorningLight,
        isFavorited: Bool = false,
        initialBackgroundStyle: HomeBackgroundStyle = .make(weather: nil),
        donationCoordinator: DonationCoordinator,
        autoPresentDonationOnAppear: Bool = false,
        onDismiss: @escaping (HomeBackgroundStyle, Data?) -> Void = { _, _ in },
        onSnooze: @escaping (HomeBackgroundStyle, Data?) -> Void = { _, _ in },
        onToggleFavorite: @escaping (Song) -> Void = { _ in }
    ) {
        self.donationCoordinator = donationCoordinator
        self.autoPresentDonationOnAppear = autoPresentDonationOnAppear
        self.onDismiss = onDismiss
        self.onSnooze = onSnooze
        self.onToggleFavorite = onToggleFavorite
        self.initialBackgroundStyle = initialBackgroundStyle
        _viewModel = StateObject(wrappedValue: RingViewModel(alarm: alarm, song: song, isFavorited: isFavorited))
        _backgroundStyle = State(initialValue: initialBackgroundStyle)
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(viewModel.ringTimeText)
                        .vibriseMavenText(size: 72)

                    Text(viewModel.ringDateText)
                        .vibriseSatoshiText(size: 16)
                }

                VStack(spacing: 40) {
                    RingCenterControlPad(
                        onTap: {
                            viewModel.handleSnooze()
                            scheduleCompletion { onSnooze(backgroundStyle, artworkImageData) }
                        },
                        onLongPress: {
                            viewModel.handleDismiss()
                            scheduleCompletion { onDismiss(backgroundStyle, artworkImageData) }
                        }
                    )

                    RingDonationButton(
                        isLoading: donationCoordinator.isPurchaseInProgress,
                        action: {
                            donationCoordinator.purchaseCoffee()
                        }
                    )
                }
                .padding(.top, 60)

                Spacer()

                RingBottomTrack(
                    song: viewModel.song,
                    isPlayingAudio: viewModel.isPlayingAudio,
                    isFavorited: viewModel.isFavorited,
                    isPreparingShare: isPreparingShare,
                    onToggleFavorite: {
                        viewModel.toggleFavorite()
                        onToggleFavorite(viewModel.song)
                    },
                    onShare: {
                        prepareShareCard()
                    }
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.pageHorizontal)
            .padding(.top, 84)
            .padding(.bottom, DesignTokens.Spacing.pageTop)

            if let message = displayedToastMessage {
                VibriseTopToastOverlay(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            #if canImport(UIKit)
            if let sharePreviewImage {
                ShareView(image: sharePreviewImage) {
                    self.sharePreviewImage = nil
                }
                .transition(.opacity)
                .zIndex(10)
            }
            #endif

            if donationCoordinator.isShowingThanksOverlay {
                ThanksOverlayView(message: donationCoordinator.thanksMessage)
                    .zIndex(20)
            }
        }
        .animation(.easeOut(duration: 0.24), value: viewModel.transientMessage)
        .animation(.easeOut(duration: 0.24), value: donationCoordinator.transientMessage)
        .animation(.easeOut(duration: 0.24), value: donationCoordinator.isShowingThanksOverlay)
        #if canImport(UIKit)
        .animation(.easeOut(duration: 0.24), value: sharePreviewImage != nil)
        #endif
        .onChange(of: viewModel.transientMessage) { _, newValue in
            if donationCoordinator.transientMessage == nil {
                scheduleToastClearIfNeeded(message: newValue)
            }
        }
        .onChange(of: donationCoordinator.transientMessage) { _, newValue in
            scheduleToastClearIfNeeded(message: newValue)
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                viewModel.recoverPlaybackIfNeeded()
            }
        }
        .onAppear {
            backgroundStyle = initialBackgroundStyle
            donationCoordinator.prepareStoreIfNeeded()
            viewModel.startPlayback()
            if autoPresentDonationOnAppear {
                autoDonationTask?.cancel()
                autoDonationTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    donationCoordinator.purchaseCoffee()
                }
            }
        }
        .task(id: viewModel.song.id) {
            await updateBackgroundStyleFromArtwork()
        }
        .onDisappear {
            viewModel.stopPlayback()
            completionTask?.cancel()
            toastTask?.cancel()
            shareTask?.cancel()
            autoDonationTask?.cancel()
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            RingAmbientBackgroundView(style: backgroundStyle, seed: orbSeed)

            #if canImport(UIKit)
            if let artworkBackgroundImage {
                GeometryReader { geo in
                    Image(uiImage: artworkBackgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .blur(radius: 60)
                .overlay(Color.black.opacity(0.35))
                .ignoresSafeArea()
                .transition(.opacity)
            }
            #endif

            HomeBackgroundOrbField(colors: backgroundStyle.orbColors, layoutSeed: orbSeed)
                .opacity(0.82)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.7), value: artworkBackgroundImage != nil)
    }

    private var displayedToastMessage: String? {
        donationCoordinator.transientMessage ?? viewModel.transientMessage
    }

    private func scheduleCompletion(_ action: @escaping () -> Void) {
        completionTask?.cancel()
        completionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            action()
        }
    }

    private func scheduleToastClearIfNeeded(message: String?) {
        toastTask = TransientToastScheduler.reschedule(
            existingTask: toastTask,
            message: message,
            isBlocked: donationCoordinator.transientMessage != nil
        ) {
            viewModel.clearTransientMessage()
        }
    }

    private func prepareShareCard() {
        #if canImport(UIKit)
        guard !isPreparingShare else {
            return
        }

        viewModel.showTransientMessage("Preparing share image")
        isPreparingShare = true
        shareTask?.cancel()

        shareTask = Task { @MainActor in
            defer {
                isPreparingShare = false
            }

            do {
                let image = try await ShareCardRenderer.makeImage(
                    song: viewModel.song,
                    shareMonthText: viewModel.shareMonthText,
                    shareDayText: viewModel.shareDayText
                )
                sharePreviewImage = image
                viewModel.clearTransientMessage()
            } catch {
                viewModel.showTransientMessage("Couldn't prepare share image")
            }
        }
        #else
        viewModel.showTransientMessage("Share isn't available on this platform")
        #endif
    }

    private func updateBackgroundStyleFromArtwork() async {
        #if canImport(UIKit)
        guard let result = await RingArtworkBackgroundLoader.load(
            from: viewModel.song.artworkURL,
            fallback: initialBackgroundStyle
        ) else {
            return
        }

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.7)) {
                backgroundStyle = result.style
                artworkBackgroundImage = result.image
                artworkImageData = result.imageData
            }
        }
        #endif
    }
}

#Preview {
    RingView(alarm: .mockWeekdayMorning, donationCoordinator: DonationCoordinator())
}
