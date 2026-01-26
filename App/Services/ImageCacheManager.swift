import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("CritterImages")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
        return cacheDir
    }()
    
    private init() {}
    
    // Generate a safe filename from URL
    private func cacheKey(for url: String) -> String {
        // Use SHA256 hash for consistent, filesystem-safe filenames
        guard let data = url.data(using: .utf8) else {
            return UUID().uuidString
        }
        
        let hash = data.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .prefix(64) // Limit length
        
        return String(hash)
    }
    
    // Get cached image if it exists
    func getCachedImage(for urlString: String) -> UIImage? {
        let key = cacheKey(for: urlString)
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    // Save image to disk
    func cacheImage(_ image: UIImage, for urlString: String) {
        let key = cacheKey(for: urlString)
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: fileURL)
    }
    
    // Download and cache image
    func downloadAndCache(urlString: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = getCachedImage(for: urlString) {
            return cachedImage
        }
        
        // Download if not cached
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // Cache it
        cacheImage(image, for: urlString)
        
        return image
    }
    
    // Clear all cached images (for settings/data management)
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        // Recreate directory
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // Get cache size
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }
        
        return totalSize
    }
}
