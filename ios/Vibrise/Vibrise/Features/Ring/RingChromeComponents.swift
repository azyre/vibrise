import SwiftUI

struct RingCenterControlPad: View {
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Hold to dismiss")
                .vibriseSatoshiText(size: 16)

            Text("Tap to snooze")
                .vibriseSatoshiText(size: 16, color: DesignTokens.Colors.secondaryText)
        }
        .frame(width: 320, height: 320)
        .background(ringGlassCircleFill)
        .overlay {
            Circle()
                .stroke(DesignTokens.Colors.surfaceBorder, lineWidth: DesignTokens.Border.regular)
        }
        .clipShape(Circle())
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.8, perform: onLongPress)
    }
}

struct RingDonationButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(DesignTokens.Colors.primaryText)
                } else {
                    Image(systemName: "cup.and.saucer")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.primaryText)
                }
            }
            .frame(width: 60, height: 60)
            .background(ringGlassCircleFill)
            .overlay {
                Circle()
                    .stroke(DesignTokens.Colors.surfaceBorder, lineWidth: DesignTokens.Border.regular)
            }
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct RingBottomTrack: View {
    let song: Song
    let isPlayingAudio: Bool
    let isFavorited: Bool
    let isPreparingShare: Bool
    let onToggleFavorite: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: song.artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.thumbnail, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: DesignTokens.Size.smallIcon, weight: .medium))
                                .foregroundStyle(DesignTokens.Colors.primaryText)
                        }
                }
            }
            .frame(width: DesignTokens.Size.toolbarButton, height: DesignTokens.Size.toolbarButton)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.thumbnail, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.thumbnail, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: DesignTokens.Border.regular)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(song.title)
                    .vibriseSatoshiText(size: 16)
                    .lineLimit(1)

                Text(song.artist)
                    .vibriseSatoshiText(size: 16, color: DesignTokens.Colors.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                if isPlayingAudio {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: DesignTokens.Size.smallIcon, weight: .regular))
                        .foregroundStyle(DesignTokens.Colors.secondaryText)
                }

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: DesignTokens.Size.bodyIcon, weight: .regular))
                        .foregroundStyle(DesignTokens.Colors.primaryText)
                }
                .buttonStyle(.plain)

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: isPreparingShare ? DesignTokens.Spacing.medium : DesignTokens.Size.bodyIcon, weight: .regular))
                        .foregroundStyle(DesignTokens.Colors.primaryText)
                        .overlay {
                            if isPreparingShare {
                                ProgressView()
                                    .tint(DesignTokens.Colors.primaryText)
                                    .scaleEffect(0.7)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.track, style: .continuous)
                .fill(DesignTokens.Colors.surface)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.track, style: .continuous))
        )
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.track, style: .continuous)
                .stroke(DesignTokens.Colors.surfaceBorder, lineWidth: DesignTokens.Border.regular)
        }
    }
}

private var ringGlassCircleFill: some View {
    Circle()
        .fill(DesignTokens.Colors.surface)
        .background(.ultraThinMaterial, in: Circle())
}
