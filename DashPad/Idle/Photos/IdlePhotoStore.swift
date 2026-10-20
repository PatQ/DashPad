// DashPad: https://github.com/rafapages/DashPad
// Licensed under PolyForm Noncommercial 1.0.0. Commercial use requires a separate license: dashpad@rafapages.com

// IdlePhotoStore.swift - DashPad's own copies of the idle screen photos: importing, thumbnails, and
// decoding a photo ready to show.

import CoreImage
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Photos are copied in rather than referenced in the photo library. A reference would need full
/// library access, and would break when the original is deleted or lives only in iCloud. Each
/// copy is shrunk to screen size on import, so a 48 MP original costs about a megabyte on disk
/// and a screenful of pixels in memory.
///
/// Nonisolated (the project defaults to the main actor) because importing and decoding run on
/// background threads.
nonisolated enum IdlePhotoStore {
    /// Long edge of the largest iPad screen (13-inch iPad Pro, 2752 × 2064 pixels). Anything
    /// bigger is never seen.
    private static let maxPixelSize = 2752
    private static let thumbnailPixelSize = 256

    private static let directory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var url = base.appendingPathComponent("IdlePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        // PRIVACY.md promises nothing is backed up to a cloud service; personal photos least of all.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        return url
    }()

    private static func url(for photo: IdlePhoto) -> URL {
        directory.appendingPathComponent(photo.id.uuidString).appendingPathExtension("jpg")
    }

    // MARK: - Import

    /// Copies the image at `source` in, shrunk to screen size, upright, and in standard dynamic
    /// range (an HDR original would otherwise glare on newer iPads). Slow: call off the main thread.
    static func importImage(at source: URL) -> IdlePhoto? {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,   // never the small embedded preview
            kCGImageSourceCreateThumbnailWithTransform: true,     // apply the EXIF orientation
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return nil }

        let photo = IdlePhoto(id: UUID())
        guard let destination = CGImageDestinationCreateWithURL(
            url(for: photo) as CFURL, UTType.jpeg.identifier as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? photo : nil
    }

    static func delete(_ photo: IdlePhoto) {
        try? FileManager.default.removeItem(at: url(for: photo))
        thumbnailCache.removeObject(forKey: photo.id as NSUUID)
    }

    /// Deletes files no setting refers to, left behind if the app quit in the middle of an import.
    static func removeFiles(notIn photos: [IdlePhoto]) {
        let keep = Set(photos.map { url(for: $0).lastPathComponent })
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where !keep.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Reading

    private static let thumbnailCache = NSCache<NSUUID, UIImage>()

    /// A small square-ish preview for the Settings grid. Call off the main thread.
    static func thumbnail(for photo: IdlePhoto) -> UIImage? {
        if let cached = thumbnailCache.object(forKey: photo.id as NSUUID) { return cached }
        guard let image = downsample(url(for: photo), to: thumbnailPixelSize) else { return nil }
        let thumbnail = UIImage(cgImage: image)
        thumbnailCache.setObject(thumbnail, forKey: photo.id as NSUUID)
        return thumbnail
    }

    /// The photo decoded and ready to draw, so the crossfade doesn't stutter while it decodes on
    /// the main thread. With `backdrop`, also a blurred copy to fill around a fitted photo.
    /// Call off the main thread.
    static func prepareSlide(_ photo: IdlePhoto, withBackdrop backdrop: Bool) -> PreparedSlide? {
        guard let image = UIImage(contentsOfFile: url(for: photo).path)?.preparingForDisplay() else { return nil }
        return PreparedSlide(
            photo: photo,
            image: image,
            backdrop: backdrop ? blurredBackdrop(for: photo) : nil,
            motionSeed: Int.random(in: 0..<1024)
        )
    }

    private static let ciContext = CIContext(options: [.cacheIntermediates: false])

    /// Blurring a small copy is far cheaper than a live blur, and nobody can tell the difference
    /// once it's stretched behind the photo.
    private static func blurredBackdrop(for photo: IdlePhoto) -> UIImage? {
        guard let small = downsample(url(for: photo), to: 160) else { return nil }
        let input = CIImage(cgImage: small)
        // Clamped first so the blur doesn't pull in transparent black at the edges; darkened a
        // little so the photo itself stands out.
        let blurred = input.clampedToExtent()
            .applyingGaussianBlur(sigma: 10)
            .applyingFilter("CIColorControls", parameters: [kCIInputBrightnessKey: -0.12])
            .cropped(to: input.extent)
        guard let output = ciContext.createCGImage(blurred, from: input.extent) else { return nil }
        return UIImage(cgImage: output)
    }

    private static func downsample(_ url: URL, to maxPixels: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}

/// A photo decoded and ready to go on screen.
nonisolated struct PreparedSlide {
    /// Distinguishes two showings of the same photo, so a one-photo loop still counts as new.
    let token = UUID()
    let photo: IdlePhoto
    let image: UIImage
    let backdrop: UIImage?
    /// Picks this showing's zoom and pan direction.
    let motionSeed: Int
}
