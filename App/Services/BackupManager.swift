import Foundation
import SwiftData
import Combine
import ZIPFoundation // We'll need to add this package

struct CollectionBackup: Codable {
    let exportDate: Date
    let appVersion: String
    let ownedVariants: [BackupVariant]
    let photos: [BackupPhoto]
    
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
    
    struct BackupPhoto: Codable {
        let id: String
        let variantUuid: String
        let filename: String
        let caption: String?
        let capturedDate: Date
        let sortOrder: Int
    }
}

class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    @Published var lastBackupDate: Date?
    @Published var isExporting = false
    @Published var isImporting = false
    
    private init() {
        if let timestamp = UserDefaults.standard.object(forKey: Config.UserDefaultsKeys.lastBackupDate) as? Date {
            lastBackupDate = timestamp
        }
    }
    
    // MARK: - Export
    
    /// Export collection and photos to ZIP file
    func exportCollection(ownedVariants: [OwnedVariant], photos: [VariantPhoto], appVersion: String) throws -> URL {
        isExporting = true
        defer { isExporting = false }
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create photos directory
        let photosDir = tempDir.appendingPathComponent("photos")
        try fileManager.createDirectory(at: photosDir, withIntermediateDirectories: true)
        
        // Save photos and build metadata
        var backupPhotos: [CollectionBackup.BackupPhoto] = []
        
        for photo in photos {
            let filename = "\(photo.variantUuid)_\(photo.id.uuidString).jpg"
            let photoURL = photosDir.appendingPathComponent(filename)
            try photo.imageData.write(to: photoURL)
            
            backupPhotos.append(CollectionBackup.BackupPhoto(
                id: photo.id.uuidString,
                variantUuid: photo.variantUuid,
                filename: filename,
                caption: photo.caption,
                capturedDate: photo.capturedDate,
                sortOrder: photo.sortOrder
            ))
        }
        
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
            ownedVariants: backupVariants,
            photos: backupPhotos
        )
        
        // Save JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(backup)
        let jsonURL = tempDir.appendingPathComponent("backup.json")
        try jsonData.write(to: jsonURL)
        
        // Create ZIP
        let dateString = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
        let zipFilename = "\(Config.appName)_Backup_\(dateString).zip"
        let zipURL = fileManager.temporaryDirectory.appendingPathComponent(zipFilename)
        
        // Remove existing zip if present
        try? fileManager.removeItem(at: zipURL)
        
        try fileManager.zipItem(at: tempDir, to: zipURL)
        
        // Cleanup temp directory
        try? fileManager.removeItem(at: tempDir)
        
        // Update last backup timestamp
        let now = Date()
        lastBackupDate = now
        UserDefaults.standard.set(now, forKey: Config.UserDefaultsKeys.lastBackupDate)
        
        AppLogger.info("Exported backup with \(backupVariants.count) variants and \(backupPhotos.count) photos")
        
        return zipURL
    }
    
    // MARK: - Import
    
    /// Import collection and photos from ZIP file
    func importCollection(from url: URL, into context: ModelContext) throws -> ImportResult {
        isImporting = true
        defer { isImporting = false }
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        // Check if it's a ZIP or JSON file
        let isZip = url.pathExtension.lowercased() == "zip"
        
        let jsonURL: URL
        let photosDir: URL?
        
        if isZip {
            // Unzip
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            try fileManager.unzipItem(at: url, to: tempDir)
            
            jsonURL = tempDir.appendingPathComponent("backup.json")
            photosDir = tempDir.appendingPathComponent("photos")
        } else {
            // Legacy JSON import
            jsonURL = url
            photosDir = nil
        }
        
        // Read JSON
        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(CollectionBackup.self, from: data)
        
        var imported = 0
        var updated = 0
        var photosImported = 0
        
        // Import variants
        for backupVariant in backup.ownedVariants {
            let descriptor = FetchDescriptor<OwnedVariant>(
                predicate: #Predicate { $0.variantUuid == backupVariant.variantUuid }
            )
            
            if let existing = try? context.fetch(descriptor).first {
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
        
        // Import photos
        if let photosDir = photosDir {
            for backupPhoto in backup.photos {
                // Check if photo already exists
                let photoId = UUID(uuidString: backupPhoto.id) ?? UUID()
                let descriptor = FetchDescriptor<VariantPhoto>(
                    predicate: #Predicate { $0.id == photoId }
                )
                
                if (try? context.fetch(descriptor).first) != nil {
                    continue // Skip existing photos
                }
                
                // Load photo data
                let photoURL = photosDir.appendingPathComponent(backupPhoto.filename)
                guard let imageData = try? Data(contentsOf: photoURL) else {
                    AppLogger.warning("Could not load photo: \(backupPhoto.filename)")
                    continue
                }
                
                // Create photo
                let photo = VariantPhoto(
                    variantUuid: backupPhoto.variantUuid,
                    imageData: imageData,
                    caption: backupPhoto.caption,
                    sortOrder: backupPhoto.sortOrder
                )
                photo.id = photoId
                photo.capturedDate = backupPhoto.capturedDate
                context.insert(photo)
                photosImported += 1
            }
        }
        
        try context.save()
        
        // Cleanup
        try? fileManager.removeItem(at: tempDir)
        
        AppLogger.info("Imported \(imported) variants, updated \(updated), \(photosImported) photos")
        
        return ImportResult(
            imported: imported,
            updated: updated,
            photosImported: photosImported,
            totalInBackup: backup.ownedVariants.count,
            totalPhotosInBackup: backup.photos.count,
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
        let photosImported: Int
        let totalInBackup: Int
        let totalPhotosInBackup: Int
        let backupDate: Date
        let appVersion: String
        
        var summary: String {
            """
            Imported: \(imported) new variants
            Updated: \(updated) existing
            Photos: \(photosImported) imported
            Total in backup: \(totalInBackup) variants, \(totalPhotosInBackup) photos
            Backup date: \(backupDate.formatted(date: .long, time: .shortened))
            """
        }
    }
}
