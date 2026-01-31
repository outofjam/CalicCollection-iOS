import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var showPurchaseDetails: Bool {
        didSet {
            UserDefaults.standard.set(showPurchaseDetails, forKey: Config.UserDefaultsKeys.showPurchaseDetails)
        }
    }
    
    @Published var showConfetti: Bool {
        didSet {
            UserDefaults.standard.set(showConfetti, forKey: Config.UserDefaultsKeys.showConfetti)
        }
    }
    
    @Published var collectionBadgeStyle: CollectionBadgeStyle {
        didSet {
            UserDefaults.standard.set(collectionBadgeStyle.rawValue, forKey: Config.UserDefaultsKeys.collectionBadgeStyle)
        }
    }
    
    /// User's birthday stored as "MM-dd" format to match API
    @Published var userBirthday: String? {
        didSet {
            UserDefaults.standard.set(userBirthday, forKey: Config.UserDefaultsKeys.userBirthday)
        }
    }
    
    var lastBackupDate: Date? {
        get {
            UserDefaults.standard.object(forKey: Config.UserDefaultsKeys.lastBackupDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Config.UserDefaultsKeys.lastBackupDate)
        }
    }
    
    var shouldShowBackupReminder: Bool {
        guard let lastBackup = lastBackupDate else {
            return true // Never backed up
        }
        
        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackup, to: Date()).day ?? 0
        return daysSinceBackup >= 30 // Remind every 30 days
    }
    
    /// Returns user birthday as a formatted display string (e.g., "February 16")
    var userBirthdayDisplay: String? {
        guard let birthday = userBirthday else { return nil }
        return Self.formatBirthdayForDisplay(birthday)
    }
    
    /// Check if a critter's birthday matches the user's birthday
    func isBirthdayMatch(_ critterBirthday: String?) -> Bool {
        guard let userBday = userBirthday,
              let critterBday = critterBirthday else {
            return false
        }
        return userBday == critterBday
    }
    
    /// Format "MM-dd" string to readable format (e.g., "February 16")
    static func formatBirthdayForDisplay(_ mmdd: String) -> String? {
        let parts = mmdd.split(separator: "-")
        guard parts.count == 2,
              let month = Int(parts[0]),
              let day = Int(parts[1]),
              month >= 1, month <= 12,
              day >= 1, day <= 31 else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        
        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = 2000 // Arbitrary year for formatting
        
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        
        return formatter.string(from: date)
    }
    
    /// Convert month and day integers to "MM-dd" format
    static func formatBirthdayForStorage(month: Int, day: Int) -> String {
        String(format: "%02d-%02d", month, day)
    }
    
    private init() {
        self.showPurchaseDetails = UserDefaults.standard.bool(forKey: Config.UserDefaultsKeys.showPurchaseDetails)
        // Default to true for confetti (fun by default!)
        self.showConfetti = UserDefaults.standard.object(forKey: Config.UserDefaultsKeys.showConfetti) as? Bool ?? true
        // Default to off for badge
        let badgeRaw = UserDefaults.standard.string(forKey: Config.UserDefaultsKeys.collectionBadgeStyle) ?? "off"
        self.collectionBadgeStyle = CollectionBadgeStyle(rawValue: badgeRaw) ?? .off
        // Load birthday
        self.userBirthday = UserDefaults.standard.string(forKey: Config.UserDefaultsKeys.userBirthday)
    }
}
