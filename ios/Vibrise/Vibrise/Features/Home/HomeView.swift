import SwiftUI

struct HomeView: View {
    private struct HomeChromeStyle {
        let highlightStrokeOpacity: CGFloat
        let highlightBlurRadius: CGFloat
        let highlightStrokeWidth: CGFloat
        let baseStrokeOpacity: CGFloat
    }

    private static let homeChromeStyle = HomeChromeStyle(
        highlightStrokeOpacity: DesignTokens.Chrome.homeHighlightStrokeOpacity,
        highlightBlurRadius: DesignTokens.Chrome.homeHighlightBlurRadius,
        highlightStrokeWidth: DesignTokens.Chrome.homeHighlightStrokeWidth,
        baseStrokeOpacity: DesignTokens.Chrome.homeBaseStrokeOpacity
    )

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var donationCoordinator = DonationCoordinator()
    @State private var editingAlarm: Alarm?
    @State private var isShowingFavorites = false
    @State private var homeToastTask: Task<Void, Never>?
    @State private var autoPresentDonationOnRing = false

    private let alarmEditorTransitionDuration: CGFloat = 0.24

    var body: some View {
        ZStack {
            homeContent
                .scaleEffect(isPrimaryOverlayPresented ? 1.02 : 1)
                .opacity(isPrimaryOverlayPresented ? 0 : 1)
                .allowsHitTesting(!isPrimaryOverlayPresented)

            if isPrimaryOverlayPresented {
                homeContent
                    .scaleEffect(1.02)
                    .background(Color.black)
                    .compositingGroup()
                    .blur(radius: 40, opaque: true)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(10)
            }

            if let alarm = editingAlarm {
                AlarmSettingView(
                    alarm: alarm,
                    onSave: { savedAlarm in
                        viewModel.save(savedAlarm)
                    },
                    onClose: {
                        editingAlarm = nil
                    }
                )
                .transition(
                    .scale(scale: 1.02)
                        .combined(with: .opacity)
                )
                .zIndex(30)
            }

            if isShowingFavorites {
                FavoritesView(
                    favoriteSongs: viewModel.favoriteSongs,
                    onClose: {
                        isShowingFavorites = false
                    }
                )
                .transition(
                    .scale(scale: 1.02)
                        .combined(with: .opacity)
                )
                .zIndex(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: alarmEditorTransitionDuration), value: isPrimaryOverlayPresented)
        .ringSessionPresentation(item: $viewModel.activeRingSession) { session in
            RingView(
                alarm: session.alarm,
                song: session.song,
                isFavorited: viewModel.isFavorite(session.song),
                initialBackgroundStyle: viewModel.homeBackgroundStyle,
                donationCoordinator: donationCoordinator,
                autoPresentDonationOnAppear: autoPresentDonationOnRing,
                onDismiss: { albumCoverStyle, artworkData in
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        viewModel.applyAlbumCoverBackgroundStyle(albumCoverStyle, artworkData: artworkData)
                    }
                    viewModel.dismissActiveRingSession()
                },
                onSnooze: { albumCoverStyle, artworkData in
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        viewModel.applyAlbumCoverBackgroundStyle(albumCoverStyle, artworkData: artworkData)
                    }
                    viewModel.snoozeActiveRingSession(minutes: 10)
                },
                onToggleFavorite: { song in
                    viewModel.toggleFavorite(song: song)
                }
            )
        }
        .overlay(alignment: .top) {
            if let message = displayedToastMessage {
                VibriseTopToastOverlay(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay {
            if donationCoordinator.isShowingThanksOverlay {
                ThanksOverlayView(message: donationCoordinator.thanksMessage)
                    .zIndex(20)
            }
        }
        .animation(.easeOut(duration: 0.24), value: viewModel.transientMessage)
        .animation(.easeOut(duration: 0.24), value: donationCoordinator.transientMessage)
        .animation(.easeOut(duration: 0.24), value: donationCoordinator.isShowingThanksOverlay)
        .onChange(of: viewModel.transientMessage) { _, newValue in
            if donationCoordinator.transientMessage == nil {
                scheduleHomeToastClearIfNeeded(message: newValue)
            }
        }
        .onChange(of: donationCoordinator.transientMessage) { _, newValue in
            scheduleHomeToastClearIfNeeded(message: newValue)
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                viewModel.handleSceneBecameActive()
            }
        }
        .onChange(of: viewModel.activeRingSession) { _, newValue in
            autoPresentDonationOnRing = newValue == nil ? false : viewModel.consumeAutoPresentDonationOnRing()
        }
        .task {
            donationCoordinator.prepareStoreIfNeeded()
        }
        .onDisappear {
            homeToastTask?.cancel()
        }
    }

    private var homeContent: some View {
        VStack(spacing: 0) {
            header

            content
                .padding(.top, DesignTokens.Spacing.headerToContent)
                .frame(maxHeight: .infinity)

            bottomBar
        }
        .padding(.horizontal, DesignTokens.Spacing.pageHorizontal)
        .padding(.top, DesignTokens.Spacing.homeHeaderTopInset)
        .padding(.bottom, DesignTokens.Spacing.pageBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            HomeBackgroundView(
                style: viewModel.homeBackgroundStyle,
                seed: viewModel.homeBackgroundSeed,
                artworkImageData: viewModel.albumCoverImageData
            )
        }
        .ignoresSafeArea()
    }

    private var isAlarmEditorPresented: Bool {
        editingAlarm != nil
    }

    private var isPrimaryOverlayPresented: Bool {
        isAlarmEditorPresented || isShowingFavorites
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Vibrise")
                .font(DesignTokens.Typography.mavenProFont(size: 48))
                .tracking(DesignTokens.Typography.tracking(for: 48))
                .foregroundStyle(.white)

            Text("Wake up delighted everyday")
                .font(DesignTokens.Typography.satoshiFont(size: 16))
                .lineSpacing(DesignTokens.Typography.satoshiLineSpacing(for: 16))
                .foregroundStyle(.white.opacity(0.2))
                .blendMode(.plusLighter)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.alarms.isEmpty {
            emptyStateButton
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(viewModel.alarms) { alarm in
                        AlarmCard(
                            alarm: alarm,
                            onTest: {
                                viewModel.startTestingAlarm(alarm)
                            },
                            onTap: {
                                editingAlarm = alarm
                            },
                            onToggle: { isEnabled in
                                viewModel.toggleAlarm(alarm.id, isEnabled: isEnabled)
                            },
                            highlightStrokeOpacity: Self.homeChromeStyle.highlightStrokeOpacity,
                            highlightBlurRadius: Self.homeChromeStyle.highlightBlurRadius,
                            highlightStrokeWidth: Self.homeChromeStyle.highlightStrokeWidth,
                            baseStrokeOpacity: Self.homeChromeStyle.baseStrokeOpacity
                        )
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    private var emptyStateButton: some View {
        Button {
            editingAlarm = viewModel.makeNewAlarmDraft()
        } label: {
            EmptyStateCard(
                title: "No alarm yet",
                subtitle: "Tap here to set your alarm"
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        HStack(spacing: DesignTokens.Spacing.cardGap) {
            Button {
                isShowingFavorites = true
            } label: {
                Image(systemName: "heart")
                    .font(.system(size: DesignTokens.Size.bodyIcon, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(
                        width: DesignTokens.Size.toolbarButton,
                        height: DesignTokens.Size.toolbarButton
                    )
                    .homeMaterialChrome(
                        Circle(),
                        highlightStrokeOpacity: Self.homeChromeStyle.highlightStrokeOpacity,
                        highlightBlurRadius: Self.homeChromeStyle.highlightBlurRadius,
                        highlightStrokeWidth: Self.homeChromeStyle.highlightStrokeWidth,
                        baseStrokeOpacity: Self.homeChromeStyle.baseStrokeOpacity
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                donationCoordinator.purchaseCoffee()
            } label: {
                HStack(spacing: 12) {
                    Group {
                        if donationCoordinator.isPurchaseInProgress {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "cup.and.saucer")
                                .font(.system(size: DesignTokens.Size.bodyIcon, weight: .regular))
                        }
                    }
                    .frame(width: DesignTokens.Size.bodyIcon, height: DesignTokens.Size.bodyIcon)

                    Text("Buy me a coffee")
                        .font(DesignTokens.Typography.satoshiFont(size: 16))
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.leading, 24)
                .padding(.trailing, DesignTokens.Spacing.large)
                .frame(height: DesignTokens.Size.toolbarButton)
                .homeMaterialChrome(
                    Capsule(),
                    highlightStrokeOpacity: Self.homeChromeStyle.highlightStrokeOpacity,
                    highlightBlurRadius: Self.homeChromeStyle.highlightBlurRadius,
                    highlightStrokeWidth: Self.homeChromeStyle.highlightStrokeWidth,
                    baseStrokeOpacity: Self.homeChromeStyle.baseStrokeOpacity
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var displayedToastMessage: String? {
        donationCoordinator.transientMessage ?? viewModel.transientMessage
    }

    private func scheduleHomeToastClearIfNeeded(message: String?) {
        homeToastTask = TransientToastScheduler.reschedule(
            existingTask: homeToastTask,
            message: message,
            isBlocked: donationCoordinator.transientMessage != nil
        ) {
            viewModel.clearTransientMessage()
        }
    }
}

#Preview {
    HomeView()
}

private extension View {
    @ViewBuilder
    func ringSessionPresentation<Content: View>(
        item: Binding<RingSession?>,
        @ViewBuilder content: @escaping (RingSession) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }

    @ViewBuilder
    func favoritesPresentation<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented, content: content)
        #else
        sheet(isPresented: isPresented, content: content)
        #endif
    }

    @ViewBuilder
    func transparentPresentationBackgroundIfAvailable() -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            presentationBackground(.clear)
        } else {
            self
        }
    }
}
