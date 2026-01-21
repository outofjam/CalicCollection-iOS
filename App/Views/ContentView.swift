//
//  ContentView.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-20.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var searchText = ""
    @AppStorage(Config.UserDefaultsKeys.hasCompletedFirstSync) private var hasCompletedFirstSync = false
    
    var body: some View {
        if !hasCompletedFirstSync {
            FirstSyncView()
        } else {
            TabView {
                Tab("Collection", systemImage: "star.fill") {
                    Text("Collection Coming Soon")
                }
                
                Tab("Wishlist", systemImage: "heart.fill") {
                    Text("Wishlist Coming Soon")
                }
                
                Tab("Settings", systemImage: "gearshape.fill") {
                    Text("Settings Coming Soon")
                }
                
                // Search Tab - expands when tapped
                Tab(role: .search) {
                    NavigationStack {
                        SearchView(searchText: $searchText)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: OwnedVariant.self, inMemory: true)
        .environmentObject(SyncService.shared)
}
