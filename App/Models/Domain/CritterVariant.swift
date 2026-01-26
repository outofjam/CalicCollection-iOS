import Foundation
import SwiftData

/// Browse cache: Critter variant (specific product release, temporary, synced from API)
@Model
final class CritterVariant {
    @Attribute(.unique) var uuid: String
    var critterId: String
    var name: String
    var sku: String?
    var barcode: String?
    var imageURL: String?
    var thumbnailURL: String?
    var releaseYear: Int?
    var notes: String?
    var setId: String?
    var setName: String?
    var epochId: String?
    var lastSynced: Date
    var isPrimary: Bool? = false
    
    init(
        uuid: String,
        critterId: String,
        name: String,
        sku: String? = nil,
        barcode: String? = nil,
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
        releaseYear: Int? = nil,
        notes: String? = nil,
        setId: String? = nil,
        setName: String? = nil,
        epochId: String? = nil,
        lastSynced: Date = Date(),
        isPrimary: Bool? = nil
    ) {
        self.uuid = uuid
        self.critterId = critterId
        self.name = name
        self.sku = sku
        self.barcode = barcode
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.releaseYear = releaseYear
        self.notes = notes
        self.setId = setId
        self.setName = setName
        self.epochId = epochId
        self.lastSynced = lastSynced
        self.isPrimary = isPrimary
    }
    
    /// Create from API response
    convenience init(from response: VariantResponse) {
        self.init(
            uuid: response.uuid,
            critterId: response.critterId,
            name: response.name,
            sku: response.sku,
            barcode: response.barcode,
            imageURL: response.imageUrl,
            thumbnailURL: response.thumbnailUrl,
            releaseYear: response.releaseYear,
            notes: response.notes,
            setId: response.setId,
            setName: response.setName,
            epochId: response.epochId,
            isPrimary: response.isPrimary
        )
    }
}
