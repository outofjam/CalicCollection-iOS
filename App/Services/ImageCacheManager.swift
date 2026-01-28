import Foundation
import UIKit
import CryptoKit

final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let fileManager = FileManager.default
    
    private lazy var cacheDirectory: URL = {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("CritterImages")
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(
                at: cacheDir,
                withIntermediateDirectories: true
            )
        }
        
        return cacheDir
    }()
    
    private init() {}
    
    // MARK: - Cache Key (SHA256)
    
    private func cacheKey(for url: String) -> String {
        let data = Data(url.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Read
    
    func getCachedImage(for urlString: String) -> UIImage? {
        let key = cacheKey(for: urlString)
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard
            let data = try? Data(contentsOf: fileURL),
            let image = UIImage(data: data)
        else {
            return nil
        }
        
        return image
    }
    
    // MARK: - Write
    
    func cacheImage(_ image: UIImage, for urlString: String) {
        let key = cacheKey(for: urlString)
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        try? data.write(to: fileURL, options: .atomic)
    }
    
    // MARK: - Download + Cache
    
    func downloadAndCache(urlString: String) async -> UIImage? {
        // Check cache first
        if let cached = getCachedImage(for: urlString) {
            return cached
        }
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            // Use NetworkConfig.session for consistent timeout/retry behavior
            let (data, _) = try await NetworkConfig.session.data(from: url)
            
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            cacheImage(image, for: urlString)
            return image
        } catch {
            AppLogger.debug("Image download failed for \(urlString): \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Maintenance
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
        AppLogger.info("Image cache cleared")
    }
    
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(values?.fileSize ?? 0)
        }
        
        return totalSize
    }
}
