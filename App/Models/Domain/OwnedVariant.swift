import Foundation
import SwiftData

/// User's collection/wishlist: Tracks ownership of specific variant (permanent, offline)
@Model
final class OwnedVariant {
    @Attribute(.unique) var variantUuid: String
    var critterUuid: String
    var critterName: String
    var variantName: String
    var familyId: String
    var familyName: String?
    var familySpecies: String?
    var memberType: String
    var role: String?
    
    // Set/epoch info for display
    var epochId: String?
    var setName: String?
    
    // Remote URLs (for reference/re-download)
    var imageURL: String?
    var thumbnailURL: String?
    
    // Local cached paths (for offline access)
    var localImagePath: String?
    var localThumbnailPath: String?
    
    var statusRaw: String
    var photoPath: String?
    var addedDate: Date

    // Purchase tracking (optional, for collectors)
    var pricePaid: Double?
    var purchaseDate: Date?
    var purchaseLocation: String?
    var condition: String?
    var notes: String?
    var quantity: Int = 1

    /// Computed property for status enum
    var status: CritterStatus? {
        get { CritterStatus(rawValue: statusRaw) }
        set { statusRaw = newValue?.rawValue ?? "" }
    }
    
    /// Check if images are cached locally
    var hasLocalImages: Bool {
        localThumbnailPath != nil || localImagePath != nil
    }

    init(
        variantUuid: String,
        critterUuid: String,
        critterName: String,
        variantName: String,
        familyId: String,
        familyName: String? = nil,
        familySpecies: String? = nil,
        memberType: String,
        role: String? = nil,
        epochId: String? = nil,
        setName: String? = nil,
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
        localImagePath: String? = nil,
        localThumbnailPath: String? = nil,
        status: CritterStatus,
        photoPath: String? = nil,
        addedDate: Date = Date(),
        pricePaid: Double? = nil,
        purchaseDate: Date? = nil,
        purchaseLocation: String? = nil,
        condition: String? = nil,
        notes: String? = nil,
        quantity: Int = 1
    ) {
        self.variantUuid = variantUuid
        self.critterUuid = critterUuid
        self.critterName = critterName
        self.variantName = variantName
        self.familyId = familyId
        self.familyName = familyName
        self.familySpecies = familySpecies
        self.memberType = memberType
        self.role = role
        self.epochId = epochId
        self.setName = setName
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.localImagePath = localImagePath
        self.localThumbnailPath = localThumbnailPath
        self.statusRaw = status.rawValue
        self.photoPath = photoPath
        self.addedDate = addedDate
        self.pricePaid = pricePaid
        self.purchaseDate = purchaseDate
        self.purchaseLocation = purchaseLocation
        self.condition = condition
        self.notes = notes
        self.quantity = quantity
    }
}

// MARK: - Helper Methods
extension OwnedVariant {
    
    /// Create from variant picker selection (new online browse flow)
    static func create(
        variant: VariantResponse,
        critter: CritterInfo,
        familyId: String,
        status: CritterStatus,
        in context: ModelContext
    ) async throws {
        let variantUuid = variant.uuid
        
        // Check if already owned
        let descriptor = FetchDescriptor<OwnedVariant>(
            predicate: #Predicate { $0.variantUuid == variantUuid }
        )
        
        // Cache images for offline access
        let (imagePath, thumbPath) = try await ImagePersistenceService.shared.cacheImages(
            imageUrl: variant.imageUrl,
            thumbnailUrl: variant.thumbnailUrl,
            for: variantUuid
        )
        
        if let existing = try? context.fetch(descriptor).first {
            // Update existing
            existing.status = status
            existing.imageURL = variant.imageUrl
            existing.thumbnailURL = variant.thumbnailUrl
            existing.localImagePath = imagePath
            existing.localThumbnailPath = thumbPath
            existing.epochId = variant.epochId
            existing.setName = variant.setName
            if status == .collection && existing.photoPath == nil {
                existing.addedDate = Date()
            }
        } else {
            // Create new
            let owned = OwnedVariant(
                variantUuid: variant.uuid,
                critterUuid: critter.uuid,
                critterName: critter.name,
                variantName: variant.name,
                familyId: familyId,
                familyName: critter.familyName,
                memberType: critter.memberType,
                epochId: variant.epochId,
                setName: variant.setName,
                imageURL: variant.imageUrl,
                thumbnailURL: variant.thumbnailUrl,
                localImagePath: imagePath,
                localThumbnailPath: thumbPath,
                status: status
            )
            context.insert(owned)
        }
        
        try context.save()
    }
    
    /// Create from search result selection
    static func create(
        from searchResult: SearchResultResponse,
        status: CritterStatus,
        in context: ModelContext
    ) async throws {
        let variantUuid = searchResult.variantUuid
        
        // Check if already owned
        let descriptor = FetchDescriptor<OwnedVariant>(
            predicate: #Predicate { $0.variantUuid == variantUuid }
        )
        
        // Cache images for offline access
        let (imagePath, thumbPath) = try await ImagePersistenceService.shared.cacheImages(
            imageUrl: searchResult.imageUrl,
            thumbnailUrl: searchResult.thumbnailUrl,
            for: variantUuid
        )
        
        if let existing = try? context.fetch(descriptor).first {
            // Update existing
            existing.status = status
            existing.imageURL = searchResult.imageUrl
            existing.thumbnailURL = searchResult.thumbnailUrl
            existing.localImagePath = imagePath
            existing.localThumbnailPath = thumbPath
            existing.epochId = searchResult.epochId
            existing.setName = searchResult.setName
            if status == .collection && existing.photoPath == nil {
                existing.addedDate = Date()
            }
        } else {
            // Create new
            let owned = OwnedVariant(
                variantUuid: searchResult.variantUuid,
                critterUuid: searchResult.critterUuid ?? "",
                critterName: searchResult.critterName ?? "Unknown",
                variantName: searchResult.variantName,
                familyId: searchResult.familyUuid ?? "",
                familyName: searchResult.familyName,
                memberType: searchResult.memberType ?? "unknown",
                epochId: searchResult.epochId,
                setName: searchResult.setName,
                imageURL: searchResult.imageUrl,
                thumbnailURL: searchResult.thumbnailUrl,
                localImagePath: imagePath,
                localThumbnailPath: thumbPath,
                status: status
            )
            context.insert(owned)
        }
        
        try context.save()
    }
    
    /// Create from barcode scan (SetVariant)
    static func create(
        from setVariant: SetVariant,
        status: CritterStatus,
        in context: ModelContext
    ) async throws {
        let variantUuid = setVariant.uuid
        
        // Check if already owned
        let descriptor = FetchDescriptor<OwnedVariant>(
            predicate: #Predicate { $0.variantUuid == variantUuid }
        )
        
        // Cache images for offline access
        let (imagePath, thumbPath) = try await ImagePersistenceService.shared.cacheImages(
            imageUrl: setVariant.imageURL,
            thumbnailUrl: setVariant.thumbnailURL,
            for: variantUuid
        )
        
        if let existing = try? context.fetch(descriptor).first {
            // Update existing
            existing.status = status
            existing.imageURL = setVariant.imageURL
            existing.thumbnailURL = setVariant.thumbnailURL
            existing.localImagePath = imagePath
            existing.localThumbnailPath = thumbPath
            existing.epochId = setVariant.epochId
            existing.setName = setVariant.setName
            if status == .collection && existing.photoPath == nil {
                existing.addedDate = Date()
            }
        } else {
            // Create new
            let owned = OwnedVariant(
                variantUuid: setVariant.uuid,
                critterUuid: setVariant.critter.uuid,
                critterName: setVariant.critter.name,
                variantName: setVariant.name,
                familyId: setVariant.critter.family.uuid,
                familyName: setVariant.critter.family.name,
                familySpecies: setVariant.critter.family.species,
                memberType: setVariant.critter.memberType,
                role: setVariant.critter.role,
                epochId: setVariant.epochId,
                setName: setVariant.setName,
                imageURL: setVariant.imageURL,
                thumbnailURL: setVariant.thumbnailURL,
                localImagePath: imagePath,
                localThumbnailPath: thumbPath,
                status: status
            )
            context.insert(owned)
        }
        
        try context.save()
    }

    /// Remove variant from collection/wishlist
    static func remove(variantUuid: String, in context: ModelContext) throws {
        let descriptor = FetchDescriptor<OwnedVariant>(
            predicate: #Predicate { $0.variantUuid == variantUuid }
        )

        if let existing = try? context.fetch(descriptor).first {
            // Delete cached images
            ImagePersistenceService.shared.deleteCachedImage(for: variantUuid)
            context.delete(existing)
            try context.save()
        }
    }
}
