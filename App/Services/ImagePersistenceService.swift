import Foundation
import UIKit

/// Service for persisting images locally for offline access
class ImagePersistenceService {
    static let shared = ImagePersistenceService()
    
    private let fileManager = FileManager.default
    private let imageDirectory: URL
    
    private init() {
        // Get documents directory for persistent storage
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imageDirectory = documentsPath.appendingPathComponent("CachedImages", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Public Methods
    
    /// Download and save image for a variant (for offline collection/wishlist)
    /// - Parameters:
    ///   - urlString: Remote image URL
    ///   - variantUuid: Variant UUID (used as filename)
    /// - Returns: Local file path
    @discardableResult
    func cacheImage(from urlString: String?, for variantUuid: String) async throws -> String? {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return nil
        }
        
        let localPath = imagePath(for: variantUuid)
        
        // Check if already cached
        if fileManager.fileExists(atPath: localPath.path) {
            AppLogger.debug("Image already cached for variant: \(variantUuid)")
            return localPath.path
        }
        
        AppLogger.debug("Downloading image for variant: \(variantUuid)")
        
        // Download image
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            AppLogger.error("Failed to download image for variant: \(variantUuid)")
            return nil
        }
        
        // Verify it's valid image data
        guard UIImage(data: data) != nil else {
            AppLogger.error("Invalid image data for variant: \(variantUuid)")
            return nil
        }
        
        // Save to disk
        try data.write(to: localPath)
        AppLogger.debug("Cached image for variant: \(variantUuid)")
        
        return localPath.path
    }
    
    /// Cache both full image and thumbnail for a variant
    func cacheImages(
        imageUrl: String?,
        thumbnailUrl: String?,
        for variantUuid: String
    ) async throws -> (imagePath: String?, thumbnailPath: String?) {
        async let imagePath = cacheImage(from: imageUrl, for: variantUuid)
        async let thumbPath = cacheImage(from: thumbnailUrl, for: "\(variantUuid)_thumb")
        
        return try await (imagePath, thumbPath)
    }
    
    /// Get local image path for a variant
    func imagePath(for variantUuid: String) -> URL {
        imageDirectory.appendingPathComponent("\(variantUuid).jpg")
    }
    
    /// Get local thumbnail path for a variant
    func thumbnailPath(for variantUuid: String) -> URL {
        imageDirectory.appendingPathComponent("\(variantUuid)_thumb.jpg")
    }
    
    /// Check if image is cached locally
    func isImageCached(for variantUuid: String) -> Bool {
        fileManager.fileExists(atPath: imagePath(for: variantUuid).path)
    }
    
    /// Load cached image
    func loadCachedImage(for variantUuid: String) -> UIImage? {
        let path = imagePath(for: variantUuid)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }
    
    /// Load cached thumbnail
    func loadCachedThumbnail(for variantUuid: String) -> UIImage? {
        let path = thumbnailPath(for: variantUuid)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }
    
    /// Delete cached image for a variant
    func deleteCachedImage(for variantUuid: String) {
        let imagePath = imagePath(for: variantUuid)
        let thumbPath = thumbnailPath(for: variantUuid)
        
        try? fileManager.removeItem(at: imagePath)
        try? fileManager.removeItem(at: thumbPath)
        
        AppLogger.debug("Deleted cached images for variant: \(variantUuid)")
    }
    
    /// Get total size of cached images
    func cacheSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: imageDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }
        
        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + Int64(size)
        }
    }
    
    /// Format cache size for display
    func formattedCacheSize() -> String {
        let bytes = cacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Clear all cached images
    func clearCache() {
        try? fileManager.removeItem(at: imageDirectory)
        try? fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        AppLogger.debug("Cleared image cache")
    }
}
