import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var showPurchaseDetails: Bool {
        didSet {
            UserDefaults.standard.set(showPurchaseDetails, forKey: Config.UserDefaultsKeys.showPurchaseDetails)
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
    
    private init() {
        self.showPurchaseDetails = UserDefaults.standard.bool(forKey: Config.UserDefaultsKeys.showPurchaseDetails)
    }
}
