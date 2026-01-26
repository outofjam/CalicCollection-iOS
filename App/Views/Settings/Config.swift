import Foundation

/// App configuration and constants
struct Config {
    
    // MARK: - API Configuration
    
    /// Base API URL
    static var apiBaseURL: String {
#if DEBUG
        // Development URL
        return "https://calicoprod.thetechnodro.me/api/v1"
        //return "http://callicollection.test/api/v1"
#else
        // Production URL
        return "http://api.callicollection.com/api/v1"
#endif
    }
    
    // MARK: - App Information
    
    static let appName = "CaliCollection"
    static let appVersion = "2.1a"
    
    // MARK: - Sync Settings
    
    /// Days before requiring sync
    static let syncIntervalDays = 7
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        // Sync
        static let hasCompletedFirstSync = "hasCompletedFirstSync"
        static let lastSyncDate = "lastSyncDate"
        
        // Settings
        static let showPurchaseDetails = "showPurchaseDetails"
        
        // Backup
        static let lastBackupDate = "lastBackupDate"
    }
}
