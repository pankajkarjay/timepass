import Foundation
import Photos
import UIKit

final class PhotoScannerService {
    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }

    func fetchRecentScreenshotAssets(limit: Int) throws -> [PHAsset] {
        guard let screenshotsCollection = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        ).firstObject else {
            throw AppError.screenshotsAlbumNotFound
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)

        let fetchResult = PHAsset.fetchAssets(in: screenshotsCollection, options: options)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        if assets.isEmpty {
            throw AppError.noScreenshots
        }

        return assets
    }

    func loadImage(for asset: PHAsset) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.resizeMode = .none
            options.isNetworkAccessAllowed = false

            manager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard
                    let data,
                    let image = UIImage(data: data)
                else {
                    continuation.resume(throwing: AppError.imageLoadFailed)
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }
}
