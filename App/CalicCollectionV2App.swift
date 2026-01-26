//
//  CalicCollectionV2App.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-20.
//

import SwiftUI
import SwiftData

@main
struct CalicCollectionV2App: App {
    init() {
        // Configure URLCache for image caching
//        // This gives AsyncImage automatic disk + memory caching
//        ImageCacheManager.shared.configureCache()
//        let memoryCapacity = 50_000_000   // 50 MB memory cache
//        let diskCapacity = 200_000_000    // 200 MB disk cache
//        
//        URLCache.shared = URLCache(
//            memoryCapacity: memoryCapacity,
//            diskCapacity: diskCapacity,
//            directory: nil  // Uses default cache directory
//        )
        
//        print("✅ URLCache configured: \(memoryCapacity/1_000_000)MB memory, \(diskCapacity/1_000_000)MB disk -- app file")
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Browse cache (temporary data from API)
            Critter.self,
            CritterVariant.self,
            Family.self,
            // User collection (permanent data)
            OwnedVariant.self,
            VariantPhoto.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environmentObject(SyncService.shared)
        }
    }
}
