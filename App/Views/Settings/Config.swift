import Foundation

/// App configuration and constants
struct Config {
    
    // MARK: - API Configuration
    
    /// Base API URL
    static var apiBaseURL: String {
        #if DEBUG
        // Development URL
        return "http://callicollection.test/api/v1"
        #else
        // Production URL
        return "http://api.callicollection.com/api/v1"
        #endif
    }
    
    // MARK: - App Information
    
    static let appName = "CalicCollection"
    static let appVersion = "1.0"
    
    // MARK: - Sync Settings
    
    /// Days before requiring sync
    static let syncIntervalDays = 7
    
    // MARK: - User Defaults Keys
    
    struct UserDefaultsKeys {
        static let hasCompletedFirstSync = "hasCompletedFirstSync"
        static let lastSyncDate = "lastCritterSync"
    }
}
