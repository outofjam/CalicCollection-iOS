//
//  ImageCacheManager.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-25.
//


import Foundation

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private init() {
        configureCache()
    }
    
    func configureCache() {
        // Configure URLCache with larger persistent disk cache
        let memoryCapacity = 50 * 1024 * 1024  // 50 MB
        let diskCapacity = 200 * 1024 * 1024   // 200 MB
        
        // Use custom cache directory to ensure persistence
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        let cache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            directory: cacheURL
        )
        
        URLCache.shared = cache
        
        print("✅ URLCache configured: \(memoryCapacity / 1024 / 1024)MB memory, \(diskCapacity / 1024 / 1024)MB disk")
    }
}