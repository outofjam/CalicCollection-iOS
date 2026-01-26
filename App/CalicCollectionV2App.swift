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
