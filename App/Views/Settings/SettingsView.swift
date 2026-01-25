import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: SyncService
    @StateObject private var appSettings = AppSettings.shared
    
    @State private var showingSyncConfirmation = false
    @State private var refreshID = UUID()
    @State private var apiStats: APIStats?
    @State private var isLoadingStats = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Sync Section
                Section {
                    // Last sync info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Synced")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let lastSync = syncService.lastSyncDate {
                                Text(syncService.timeSinceLastSync)
                                    .font(.body)
                                    .id(refreshID)
                                
                                Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Never")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if syncService.isSyncing {
                            ProgressView()
                        }
                    }
                    
                    // Sync button
                    Button {
                        showingSyncConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Force Sync Now")
                        }
                    }
                    .disabled(syncService.isSyncing)
                    
                    // Sync status/error
                    if let error = syncService.syncError {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sync Error")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    if syncService.needsSync {
                        Text("It's been a while since your last sync. Consider syncing to get the latest critters.")
                    }
                }
                

                
                // MARK: - Preferences Section
                Section {
                    Toggle(isOn: $appSettings.showPurchaseDetails) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Purchase Details")
                                .font(.body)
                            Text("Track price, date, location, and condition")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Purchase details are optional collector features. Turn off to simplify the interface for younger users.")
                }
                
                // MARK: - About
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }


                // MARK: - Data Section
                Section {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Data Management", systemImage: "externaldrive")
                    }
                } header: {
                    Text("Data")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                refreshID = UUID()
                Task {
                    await loadStats()
                }
            }
            .alert("Force Sync?", isPresented: $showingSyncConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sync Now") {
                    Task {
                        await syncService.syncAll(modelContext: modelContext, force: true)
                    }
                }
            } message: {
                Text("This will refresh all critters and variants from the server.")
            }
        }
    }
    
    // MARK: - API Stats
    
    private func loadStats() async {
        isLoadingStats = true
        
        do {
            let stats = try await StatsService.shared.fetchStats()
            apiStats = stats
        } catch {
            print("Failed to load stats: \(error)")
            apiStats = nil
        }
        
        isLoadingStats = false
    }
}

// MARK: - Data Management View
struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var backupManager = BackupManager.shared
    @Query private var critters: [Critter]
    @Query private var variants: [CritterVariant]
    @Query private var families: [Family]
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var showingClearCacheAlert = false
    @State private var showingResetAppAlert = false
    @State private var showingClearImageCacheAlert = false
    @State private var refreshID = UUID()
    @State private var showingImportPicker = false
    @State private var showingImportResult = false
    @State private var importResultMessage = ""
    
    // Cache stats computed properties
    private var memoryCacheSize: String {
        let bytes = URLCache.shared.currentMemoryUsage
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    private var diskCacheSize: String {
        let bytes = URLCache.shared.currentDiskUsage
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    private var memoryCacheCapacity: String {
        let bytes = URLCache.shared.memoryCapacity
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    private var diskCacheCapacity: String {
        let bytes = URLCache.shared.diskCapacity
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    // Collection counts
    private var collectionCount: Int {
        ownedVariants.filter { $0.status == .collection }.count
    }
    
    private var wishlistCount: Int {
        ownedVariants.filter { $0.status == .wishlist }.count
    }
    
    // MARK: - Storage Row Views
    
    private var browseCacheRow: some View {
        HStack {
            Text("Browse Cache")
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(critters.count) critters")
                    .font(.body)
                Text("\(variants.count) variants")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var collectionRow: some View {
        HStack {
            Text("Your Collection")
            Spacer()
            Text("\(collectionCount) variants")
        }
    }
    
    private var wishlistRow: some View {
        HStack {
            Text("Your Wishlist")
            Spacer()
            Text("\(wishlistCount) variants")
        }
    }
    
    // MARK: - Cache Row Views
    
    private var memoryCacheRow: some View {
        HStack {
            Text("Memory Cache")
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(memoryCacheSize)
                    .font(.body)
                    .id(refreshID)
                Text("of \(memoryCacheCapacity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var diskCacheRow: some View {
        HStack {
            Text("Disk Cache")
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(diskCacheSize)
                    .font(.body)
                    .id(refreshID)
                Text("of \(diskCacheCapacity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                browseCacheRow
                collectionRow
                wishlistRow
            } header: {
                Text("Storage")
            }
            
            // MARK: - Backup & Restore Section
            Section {
               
                // Show last backup status
                HStack {
                    Text("Last Backup")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(BackupManager.shared.lastBackupFormatted)
                }
                
                
                // Backup reminder banner
                if AppSettings.shared.shouldShowBackupReminder {
                    backupReminderBanner
                }
                
                Button {
                    presentShareSheet()
                } label: {
                    Label("Export Backup", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingImportPicker = true
                } label: {
                    Label("Import Backup", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Backup & Restore")
            } footer: {
                Text("Export your collection as a JSON file to save to iCloud Drive or Files. Import to restore or transfer your collection to a new device.")
            }
            
            // MARK: - Image Cache Section
            Section {
                memoryCacheRow
                diskCacheRow
            } header: {
                Text("Image Cache")
            } footer: {
                Text("Images are cached for offline viewing.")
            }
            
            Section {
                Button(role: .destructive) {
                    showingClearImageCacheAlert = true
                } label: {
                    Label("Clear Image Cache", systemImage: "photo")
                }
                
                Button(role: .destructive) {
                    showingClearCacheAlert = true
                } label: {
                    Label("Clear Browse Cache", systemImage: "trash")
                }
                
                Button(role: .destructive) {
                    showingResetAppAlert = true
                } label: {
                    Label("Reset All Data", systemImage: "exclamationmark.triangle")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Clear image cache removes cached images. Clear browse cache removes downloaded critter data. Reset all data removes everything including your collection and wishlist.")
            }
        }
        .navigationTitle("Data Management")
        .alert("Clear Image Cache?", isPresented: $showingClearImageCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearImageCache()
            }
        } message: {
            Text("This will remove all cached images. They will be downloaded again when needed.")
        }
        .alert("Clear Cache?", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will remove all downloaded critter data. You can sync again to restore it.")
        }
        .alert("Reset Everything?", isPresented: $showingResetAppAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAll()
            }
        } message: {
            Text("This will delete your entire collection, wishlist, and all downloaded data. This cannot be undone!")
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert("Import Complete", isPresented: $showingImportResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importResultMessage)
        }
    }
    
    // MARK: - Subviews
    
    private var backupReminderBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            backupReminderText
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var backupReminderText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Backup Recommended")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            backupStatusText
        }
    }
    
    private var backupStatusText: some View {
        Group {
            if let lastBackup = AppSettings.shared.lastBackupDate {
                Text("Last backup: \(lastBackup.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("You haven't backed up your collection yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Backup & Restore
    
    private func presentShareSheet() {
        do {
            let url = try BackupManager.shared.exportCollection(
                ownedVariants: ownedVariants,
                appVersion: Config.appVersion
            )
            
            print("📦 Export URL: \(url)")
            print("📦 File exists: \(FileManager.default.fileExists(atPath: url.path))")
            
            // Get the window scene
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                print("❌ Could not find root view controller")
                return
            }
            
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true) {
                print("✅ Share sheet presented")
                AppSettings.shared.lastBackupDate = Date()
            }
            
        } catch {
            print("❌ Export error: \(error)")
            ToastManager.shared.show("Export failed: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        do {
            let fileURL = try result.get().first
            guard let url = fileURL else { return }
            
            // Access security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                ToastManager.shared.show("Could not access file", type: .error)
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Import
            let result = try BackupManager.shared.importCollection(from: url, into: modelContext)
            
            importResultMessage = result.summary
            showingImportResult = true
        } catch {
            ToastManager.shared.show("Import failed: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func clearImageCache() {
        URLCache.shared.removeAllCachedResponses()
        
        // Force refresh to show updated stats
        refreshID = UUID()
        
        ToastManager.shared.show("Image cache cleared", type: .success)
    }
    
    private func clearCache() {
        try? modelContext.delete(model: Critter.self)
        try? modelContext.delete(model: CritterVariant.self)
        try? modelContext.delete(model: Family.self)
        
        // Clear sync date to force resync
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.lastSyncDate)
        
        ToastManager.shared.show("Cache cleared", type: .success)
    }
    
    private func resetAll() {
        try? modelContext.delete(model: Critter.self)
        try? modelContext.delete(model: CritterVariant.self)
        try? modelContext.delete(model: Family.self)
        try? modelContext.delete(model: OwnedVariant.self)
        
        // Clear all user defaults
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.lastSyncDate)
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.hasCompletedFirstSync)
        
        ToastManager.shared.show("All data reset", type: .success)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(SyncService.shared)
    .modelContainer(for: OwnedVariant.self, inMemory: true)
}
struct SettingsIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .frame(width: 22, alignment: .center)
            .foregroundStyle(.secondary)
    }
}
