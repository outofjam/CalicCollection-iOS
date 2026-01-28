import Foundation
import SwiftData
import Combine

/// Service to sync families from API (small dataset, worth caching)
/// Critters and variants are now fetched on-demand via BrowseService
@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private init() {
        if let timestamp = UserDefaults.standard.object(forKey: Config.UserDefaultsKeys.lastSyncDate) as? Date {
            lastSyncDate = timestamp
        }
    }
    
    /// Check if sync is needed (>7 days old or never synced)
    var needsSync: Bool {
        guard let lastSync = lastSyncDate else { return true }
        let daysAgo = Calendar.current.date(byAdding: .day, value: -Config.syncIntervalDays, to: Date())!
        return lastSync < daysAgo
    }
    
    /// Get time since last sync as human-readable string
    var timeSinceLastSync: String {
        guard let lastSync = lastSyncDate else { return "Never" }
        
        let interval = Date().timeIntervalSince(lastSync)
        let days = Int(interval / 86400)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else {
            let weeks = days / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        }
    }
    
    // MARK: - Sync Methods
    
    /// Sync families from API (small dataset, cached for offline filter dropdown)
    func syncFamilies(modelContext: ModelContext, force: Bool = false) async {
        guard !isSyncing else { return }
        
        if !force && !needsSync {
            AppLogger.syncSkipped("last sync was recent")
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            AppLogger.syncStart("family")
            
            let familyResponses = try await BrowseService.shared.fetchFamilies()
            AppLogger.debug("Received \(familyResponses.count) families from API")
            
            // Clear existing families
            try modelContext.delete(model: Family.self)
            
            // Insert new families
            for response in familyResponses {
                let family = Family(from: response)
                modelContext.insert(family)
            }
            
            try modelContext.save()
            
            // Update last sync timestamp
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: Config.UserDefaultsKeys.lastSyncDate)
            
            AppLogger.syncComplete("Synced \(familyResponses.count) families successfully")
            ToastManager.shared.show("✓ Synced \(familyResponses.count) families", type: .success)
            
        } catch {
            syncError = error.localizedDescription
            AppLogger.syncError(error.localizedDescription)
            ToastManager.shared.show("Sync failed: \(error.localizedDescription)", type: .error)
        }
        
        isSyncing = false
    }
}
