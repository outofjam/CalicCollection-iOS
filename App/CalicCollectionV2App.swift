import SwiftUI
import SwiftData

@main
struct CalicCollectionV2App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Cached data (small dataset)
            Family.self,
            // User collection (permanent data, offline)
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
                .lottaPawsStyle()
        }
    }
    
    init() {
        configureLottaPawsAppearance()
    }

}


