//
//  ContentView.swift
//  CaliCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-20.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var searchText = ""
    @AppStorage(Config.UserDefaultsKeys.hasCompletedFirstSync) private var hasCompletedFirstSync = false
    
    var body: some View {
        ZStack {
            if !hasCompletedFirstSync {
                FirstSyncView()
            } else {
                TabView {
                    Tab("Collection", systemImage: "star.fill") {
                        CollectionView()
                    }
                    
                    Tab("Wishlist", systemImage: "heart.fill") {
                        WishlistView()
                    }
                    
                    Tab("Settings", systemImage: "gearshape.fill") {
                        SettingsView()
                    }
                    
                    Tab(role: .search) {
                        NavigationStack {
                            SearchView(searchText: $searchText)
                        }
                    }
                }
            }
        }
        .toast()
    }
}


#Preview {
    ContentView()
        .modelContainer(for: OwnedVariant.self, inMemory: true)
        .environmentObject(SyncService.shared)
}
