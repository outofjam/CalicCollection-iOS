import Foundation
import SwiftData

/// User's collection/wishlist: Tracks ownership of specific variant (permanent)
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
    var imageURL: String?
    var thumbnailURL: String?
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
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
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
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
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
    /// Create from variant + critter when user adds to collection/wishlist
    static func create(
        variant: CritterVariant,
        critter: Critter,
        status: CritterStatus,
        in context: ModelContext
    ) throws {
        let variantUuid = variant.uuid
        
        // Check if already owned
        let descriptor = FetchDescriptor<OwnedVariant>(
            predicate: #Predicate { $0.variantUuid == variantUuid }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            // Update existing
            existing.status = status
            existing.thumbnailURL = variant.thumbnailURL // Update thumbnail too
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
                familyId: critter.familyId,
                familyName: critter.familyName,
                familySpecies: critter.familySpecies,
                memberType: critter.memberType,
                role: critter.role,
                imageURL: variant.imageURL,
                thumbnailURL: variant.thumbnailURL,
                status: status
            )
            context.insert(owned)
        }
    }
    
    /// Remove variant from collection/wishlist
    static func remove(variantUuid: String, in context: ModelContext) throws {
        let descriptor = FetchDescriptor<OwnedVariant>(
            predicate: #Predicate { $0.variantUuid == variantUuid }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
    }
}
