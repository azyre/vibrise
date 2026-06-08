#if canImport(UIKit)
import UIKit
import Photos

enum PhotoLibrarySaver {
    @MainActor
    static func save(_ image: UIImage) async throws {
        let authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw PhotoLibrarySaverError.permissionDenied
        }

        guard let data = image.pngData() else {
            throw PhotoLibrarySaverError.encodingFailed
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PhotoLibrarySaverError.unknown)
                }
            }
        }
    }
}

enum PhotoLibrarySaverError: Error {
    case permissionDenied
    case encodingFailed
    case unknown
}
#endif
