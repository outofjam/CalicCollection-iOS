//
//  ContentView.swift
//  LottaPaws
//
//  Created by Ismail Dawoodjee on 2026-01-20.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var searchText = ""
    @AppStorage(Config.UserDefaultsKeys.hasCompletedFirstSync) private var hasCompletedFirstSync = false
    @ObservedObject private var appSettings = AppSettings.shared
    
    @Query(filter: #Predicate<OwnedVariant> { $0.statusRaw == "collection" })
    private var collectionVariants: [OwnedVariant]
    
    private var collectionBadgeCount: Int {
        switch appSettings.collectionBadgeStyle {
        case .off:
            return 0
        case .critters:
            return Set(collectionVariants.map { $0.critterUuid }).count
        case .variants:
            return collectionVariants.count
        }
    }
    
    init() {
        // Configure app-wide appearance on first init
        configureLottaPawsAppearance()
        configureLottaPawsRefreshControl()
    }
    
    var body: some View {
        ZStack {
            if !hasCompletedFirstSync {
                FirstSyncView()
            } else {
                TabView {
                    Tab("Collection", systemImage: "square.grid.2x2") {
                        NavigationStack {
                            CollectionView()
                        }
                    }
                    .badge(collectionBadgeCount)
                    
                    Tab("Wishlist", systemImage: "heart") {
                        NavigationStack {
                            WishlistView()
                        }
                    }
                    
                    Tab("Settings", systemImage: "gearshape") {
                        SettingsView()
                    }
                    
                    Tab(role: .search) {
                        NavigationStack {
                            SearchView(searchText: $searchText)
                        }
                    }
                }
                .tint(.primaryPink)
            }
        }
        .confetti()
        .birthdayMatch()
        .toast()
        .lottaPawsStyle()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: OwnedVariant.self, inMemory: true)
        .environmentObject(SyncService.shared)
}
