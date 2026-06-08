import SwiftUI

struct FavoritesView: View {
    let favoriteSongs: [Song]
    let onClose: () -> Void
    private let artworkCornerRadius: CGFloat = 8
    private let listTopFadeHeight: CGFloat = 32

    private var displayedSongs: [Song] {
        favoriteSongs.isEmpty ? Song.previewFavorites : favoriteSongs
    }

    var body: some View {
        ZStack {
            favoritesBackdrop

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ForEach(displayedSongs) { song in
                            HStack(spacing: DesignTokens.Spacing.medium) {
                                AsyncImage(url: song.artworkURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    default:
                                        RoundedRectangle(cornerRadius: artworkCornerRadius, style: .continuous)
                                            .fill(Color.white.opacity(0.10))
                                            .overlay {
                                                Image(systemName: "music.note")
                                                    .foregroundStyle(DesignTokens.Colors.primaryText)
                                            }
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: artworkCornerRadius, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(song.title)
                                        .vibriseSatoshiText(size: 16, weight: .regular)
                                        .lineLimit(1)

                                    Text(song.artist)
                                        .vibriseSatoshiText(size: 16, weight: .regular, color: Color.white.opacity(0.2))
                                        .blendMode(.plusLighter)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, listTopFadeHeight)
                    .padding(.bottom, DesignTokens.Spacing.cardGap)
                }
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: listTopFadeHeight)

                        Rectangle()
                            .fill(.black)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.pageHorizontal)
            .padding(.top, 64 + 38.4 + 23 - 32)
            .padding(.bottom, DesignTokens.Spacing.pageBottom)
        }
        .overlay(alignment: .topLeading) {
            Text("Favorites")
                .vibriseSatoshiText(size: 32, weight: .medium)
                .frame(height: 38.4, alignment: .center)
                .padding(.top, 64)
                .padding(.leading, DesignTokens.Spacing.pageHorizontal)
        }
        .overlay(alignment: .topTrailing) {
            VibriseCloseButton(action: onClose)
                .padding(.top, DesignTokens.Spacing.modalCloseTopInset)
                .padding(.trailing, DesignTokens.Spacing.pageHorizontal)
        }
    }

    private var favoritesBackdrop: some View {
        DesignTokens.Colors.overlayScrim
            .ignoresSafeArea()
    }
}

#Preview {
    FavoritesView(favoriteSongs: [], onClose: {})
}
