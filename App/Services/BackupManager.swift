import Foundation
import SwiftData
import Combine

struct CollectionBackup: Codable {
    let exportDate: Date
    let appVersion: String
    let ownedVariants: [BackupVariant]
    
    struct BackupVariant: Codable {
        let variantUuid: String
        let critterUuid: String
        let critterName: String
        let variantName: String
        let familyId: String
        let familyName: String?
        let familySpecies: String?
        let memberType: String
        let role: String?
        let imageURL: String?
        let thumbnailURL: String?
        let status: String
        let addedDate: Date
        
        // Purchase details
        let pricePaid: Double?
        let purchaseDate: Date?
        let purchaseLocation: String?
        let condition: String?
        let notes: String?
        let quantity: Int
    }
}

class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    @Published var lastBackupDate: Date?
    
    private let lastBackupKey = "lastBackupDate"
    
    private init() {
        // Load last backup date from UserDefaults
        if let timestamp = UserDefaults.standard.object(forKey: Config.UserDefaultsKeys.lastBackupDate) as? Date {
                 lastBackupDate = timestamp
             }
    }
    
    // MARK: - Export
    
    /// Export collection to JSON file
    func exportCollection(ownedVariants: [OwnedVariant], appVersion: String) throws -> URL {
        // Convert OwnedVariants to backup format
        let backupVariants = ownedVariants.map { variant in
            CollectionBackup.BackupVariant(
                variantUuid: variant.variantUuid,
                critterUuid: variant.critterUuid,
                critterName: variant.critterName,
                variantName: variant.variantName,
                familyId: variant.familyId,
                familyName: variant.familyName,
                familySpecies: variant.familySpecies,
                memberType: variant.memberType,
                role: variant.role,
                imageURL: variant.imageURL,
                thumbnailURL: variant.thumbnailURL,
                status: variant.statusRaw,
                addedDate: variant.addedDate,
                pricePaid: variant.pricePaid,
                purchaseDate: variant.purchaseDate,
                purchaseLocation: variant.purchaseLocation,
                condition: variant.condition,
                notes: variant.notes,
                quantity: variant.quantity
            )
        }
        
        let backup = CollectionBackup(
            exportDate: Date(),
            appVersion: appVersion,
            ownedVariants: backupVariants
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)
        
        // Save to temporary file
        let filename = "\(Config.appName)_Backup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: tempURL)
        
        // Update last backup timestamp
        let now = Date()
        lastBackupDate = now
        UserDefaults.standard.set(now, forKey: Config.UserDefaultsKeys.lastBackupDate)
        return tempURL
    }
    
    // MARK: - Import
    
    /// Import collection from JSON file
    func importCollection(from url: URL, into context: ModelContext) throws -> ImportResult {
        // Read file
        let data = try Data(contentsOf: url)
        
        // Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(CollectionBackup.self, from: data)
        
        var imported = 0
        var updated = 0
        
        for backupVariant in backup.ownedVariants {
            // Check if variant already exists
            let descriptor = FetchDescriptor<OwnedVariant>(
                predicate: #Predicate { $0.variantUuid == backupVariant.variantUuid }
            )
            
            if let existing = try? context.fetch(descriptor).first {
                // Update existing variant
                existing.status = CritterStatus(rawValue: backupVariant.status)
                existing.addedDate = backupVariant.addedDate
                existing.pricePaid = backupVariant.pricePaid
                existing.purchaseDate = backupVariant.purchaseDate
                existing.purchaseLocation = backupVariant.purchaseLocation
                existing.condition = backupVariant.condition
                existing.notes = backupVariant.notes
                existing.quantity = backupVariant.quantity
                updated += 1
            } else {
                // Create new variant
                let owned = OwnedVariant(
                    variantUuid: backupVariant.variantUuid,
                    critterUuid: backupVariant.critterUuid,
                    critterName: backupVariant.critterName,
                    variantName: backupVariant.variantName,
                    familyId: backupVariant.familyId,
                    familyName: backupVariant.familyName,
                    familySpecies: backupVariant.familySpecies,
                    memberType: backupVariant.memberType,
                    role: backupVariant.role,
                    imageURL: backupVariant.imageURL,
                    thumbnailURL: backupVariant.thumbnailURL,
                    status: CritterStatus(rawValue: backupVariant.status) ?? .collection,
                    addedDate: backupVariant.addedDate,
                    pricePaid: backupVariant.pricePaid,
                    purchaseDate: backupVariant.purchaseDate,
                    purchaseLocation: backupVariant.purchaseLocation,
                    condition: backupVariant.condition,
                    notes: backupVariant.notes,
                    quantity: backupVariant.quantity
                )
                context.insert(owned)
                imported += 1
            }
        }
        
        try context.save()
        
        return ImportResult(
            imported: imported,
            updated: updated,

            totalInBackup: backup.ownedVariants.count,
            backupDate: backup.exportDate,
            appVersion: backup.appVersion
        )
    }
    
    // MARK: - Helpers
    
    var lastBackupFormatted: String {
        guard let date = lastBackupDate else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    struct ImportResult {
        let imported: Int
        let updated: Int
        let totalInBackup: Int
        let backupDate: Date
        let appVersion: String
        
        var summary: String {
            """
            Imported: \(imported) new
            Updated: \(updated) existing
            Total in backup: \(totalInBackup)
            Backup date: \(backupDate.formatted(date: .long, time: .shortened))
            """
        }
    }
}
