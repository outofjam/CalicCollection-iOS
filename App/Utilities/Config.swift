import Foundation
/// App configuration and constants
struct Config {
    
    // MARK: - API Configuration
    
    /// Base API URL
    static var apiBaseURL: String {
    #if DEBUG
        // Development URL
        return "https://api.lottapaws.app/api/v1"
    #else
        // Production URL
        return "https://api.lottapaws.app/api/v1"
    #endif
    }
    
    // MARK: - URLs
    
    static let buyMeCoffeeURL = URL(string: "https://ko-fi.com/outofjam")!
    
    // MARK: - App Information

    static let appName = "LottaPaws"
    static let appVersion = "2.7a"
    
    // MARK: - Sync Settings
    
    /// Days before requiring sync
    static let syncIntervalDays = 7
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        // Sync
        static let hasCompletedFirstSync = "hasCompletedFirstSync"
        static let lastSyncDate = "lastSyncDate"
        static let showPurchaseDetails = "showPurchaseDetails"
        static let lastBackupDate = "lastBackupDate"
        static let deviceId = "deviceId"
        static let showConfetti = "showConfetti"
    }
    
    // MARK: - Device Identifier
    static var deviceId: String {
        if let existingId = UserDefaults.standard.string(forKey: UserDefaultsKeys.deviceId) {
            return existingId
        }
        
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: UserDefaultsKeys.deviceId)
        return newId
    }
}
