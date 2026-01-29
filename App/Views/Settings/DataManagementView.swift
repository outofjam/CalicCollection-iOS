//
//  DataManagementView.swift
//  LottaPaws
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var backupManager = BackupManager.shared
    
    @Query private var families: [Family]
    @Query private var ownedVariants: [OwnedVariant]
    @Query private var photos: [VariantPhoto]
    
    @State private var showingClearCacheAlert = false
    @State private var showingResetAppAlert = false
    @State private var showingClearImageCacheAlert = false
    @State private var refreshID = UUID()
    @State private var showingImportPicker = false
    @State private var showingImportResult = false
    @State private var importResultMessage = ""
    
    // MARK: - Computed Properties
    
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
    
    private var collectionCount: Int {
        ownedVariants.filter { $0.status == .collection }.count
    }
    
    private var wishlistCount: Int {
        ownedVariants.filter { $0.status == .wishlist }.count
    }
    
    private var localImageCacheSize: String {
        ImagePersistenceService.shared.formattedCacheSize()
    }
    
    // MARK: - Body
    
    var body: some View {
        List {
            storageSection
            backupStatusSection
            backupActionsSection
            imageCacheSection
            dangerZoneSection
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
            Text("This will remove cached family data. You can sync again to restore it.")
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
            allowedContentTypes: [.json, .zip],
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
    
    // MARK: - Sections
    
    private var storageSection: some View {
        Section {
            HStack {
                Text("Cached Families")
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(families.count) families")
                    .foregroundColor(.textSecondary)
            }
            
            HStack {
                Text("Your Collection")
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(collectionCount) variants")
                    .foregroundColor(.textSecondary)
            }
            
            HStack {
                Text("Your Wishlist")
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(wishlistCount) variants")
                    .foregroundColor(.textSecondary)
            }
            
            HStack {
                Text("Your Photos")
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(photos.count) photos")
                    .foregroundColor(.textSecondary)
            }
        } header: {
            Text("Storage")
        }
    }
    
    private var backupStatusSection: some View {
        Section {
            if AppSettings.shared.shouldShowBackupReminder {
                backupReminderBanner
            }
            
            LabeledContent("Last Backup") {
                Text(BackupManager.shared.lastBackupFormatted)
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    private var backupActionsSection: some View {
        Section {
            Button {
                presentShareSheet()
            } label: {
                HStack(spacing: LottaPawsTheme.spacingMD) {
                    Image(systemName: "arrow.down.doc")
                        .foregroundColor(.secondaryBlue)
                    Text("Export Backup")
                        .foregroundColor(.textPrimary)
                }
            }
            .buttonStyle(.plain)
            
            Button {
                showingImportPicker = true
            } label: {
                HStack(spacing: LottaPawsTheme.spacingMD) {
                    Image(systemName: "arrow.up.doc")
                        .foregroundColor(.successGreen)
                    Text("Import Backup")
                        .foregroundColor(.textPrimary)
                }
            }
            .buttonStyle(.plain)
        } footer: {
            Text("Export your collection and photos as a ZIP file to save to iCloud Drive or Files. Import to restore or transfer to a new device.")
        }
    }
    
    private var imageCacheSection: some View {
        Section {
            HStack {
                Text("Collection Images")
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(localImageCacheSize)
                    .foregroundColor(.textSecondary)
                    .id(refreshID)
            }
            
            HStack {
                Text("Memory Cache")
                    .foregroundColor(.textPrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(memoryCacheSize)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .id(refreshID)
                    Text("of \(memoryCacheCapacity)")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
            
            HStack {
                Text("Disk Cache")
                    .foregroundColor(.textPrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(diskCacheSize)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .id(refreshID)
                    Text("of \(diskCacheCapacity)")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
        } header: {
            Text("Image Cache")
        } footer: {
            Text("Collection images are saved locally for offline viewing. Browse images are cached temporarily.")
        }
    }
    
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showingClearImageCacheAlert = true
            } label: {
                Label("Clear Image Cache", systemImage: "photo")
                    .foregroundColor(.errorRed)
            }
            
            Button(role: .destructive) {
                showingClearCacheAlert = true
            } label: {
                Label("Clear Family Cache", systemImage: "trash")
                    .foregroundColor(.errorRed)
            }
            
            Button(role: .destructive) {
                showingResetAppAlert = true
            } label: {
                Label("Reset All Data", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.errorRed)
            }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Clear image cache removes all cached images. Clear family cache removes downloaded family data. Reset all data removes everything including your collection and wishlist.")
        }
    }
    
    // MARK: - Subviews
    
    private var backupReminderBanner: some View {
        HStack(alignment: .top, spacing: LottaPawsTheme.spacingMD) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.warningYellow)
            
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                Text("Backup Recommended")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                if let lastBackup = AppSettings.shared.lastBackupDate {
                    Text("Last backup: \(lastBackup.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                } else {
                    Text("You haven't backed up your collection yet")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(LottaPawsTheme.spacingMD)
        .foregroundStyle(.secondary)
        .background(Color.warningYellow.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM))
    }
    
    // MARK: - Actions
    
    private func presentShareSheet() {
        do {
            let url = try BackupManager.shared.exportCollection(
                ownedVariants: ownedVariants,
                photos: photos,
                appVersion: Config.appVersion
            )
            
            AppLogger.debug("Export URL: \(url)")
            AppLogger.debug("File exists: \(FileManager.default.fileExists(atPath: url.path))")
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                AppLogger.error("Could not find root view controller")
                return
            }
            
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true) {
                AppLogger.debug("Share sheet presented")
                AppSettings.shared.lastBackupDate = Date()
            }
            
        } catch {
            AppLogger.error("Export error: \(error)")
            ToastManager.shared.show("Export failed: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        do {
            let fileURL = try result.get().first
            guard let url = fileURL else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                ToastManager.shared.show("Could not access file", type: .error)
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            let result = try BackupManager.shared.importCollection(from: url, into: modelContext)
            
            importResultMessage = result.summary
            showingImportResult = true
        } catch {
            ToastManager.shared.show("Import failed: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func clearImageCache() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear local collection images
        ImagePersistenceService.shared.clearCache()
        
        refreshID = UUID()
        ToastManager.shared.show("Image cache cleared", type: .success)
    }
    
    private func clearCache() {
        // Only clear families now (critters/variants are fetched on-demand)
        try? modelContext.delete(model: Family.self)
        
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.lastSyncDate)
        ToastManager.shared.show("Cache cleared", type: .success)
    }
    
    private func resetAll() {
        // Clear all local data
        try? modelContext.delete(model: Family.self)
        try? modelContext.delete(model: OwnedVariant.self)
        try? modelContext.delete(model: VariantPhoto.self)
        
        // Clear image cache
        ImagePersistenceService.shared.clearCache()
        URLCache.shared.removeAllCachedResponses()
        
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.lastSyncDate)
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.hasCompletedFirstSync)
        ToastManager.shared.show("All data reset", type: .success)
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
    }
    .modelContainer(for: [OwnedVariant.self, VariantPhoto.self, Family.self], inMemory: true)
}
