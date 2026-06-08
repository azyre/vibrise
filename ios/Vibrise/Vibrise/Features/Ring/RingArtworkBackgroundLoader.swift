#if canImport(UIKit)
import UIKit

struct RingArtworkBackgroundLoadResult {
    let style: HomeBackgroundStyle
    let image: UIImage
    let imageData: Data
}

enum RingArtworkBackgroundLoader {
    static func load(
        from artworkURL: URL?,
        fallback: HomeBackgroundStyle
    ) async -> RingArtworkBackgroundLoadResult? {
        guard let artworkURL else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: artworkURL)
            guard let image = UIImage(data: data) else {
                return nil
            }

            return RingArtworkBackgroundLoadResult(
                style: makeRingArtworkBackgroundStyle(from: image, fallback: fallback),
                image: image,
                imageData: data
            )
        } catch {
            return nil
        }
    }
}
#endif
