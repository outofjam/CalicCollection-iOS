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
    var releaseYear: Int?
    var notes: String?
    var lastSynced: Date
    
    init(
        uuid: String,
        critterId: String,
        name: String,
        sku: String? = nil,
        barcode: String? = nil,
        imageURL: String? = nil,
        releaseYear: Int? = nil,
        notes: String? = nil,
        lastSynced: Date = Date()
    ) {
        self.uuid = uuid
        self.critterId = critterId
        self.name = name
        self.sku = sku
        self.barcode = barcode
        self.imageURL = imageURL
        self.releaseYear = releaseYear
        self.notes = notes
        self.lastSynced = lastSynced
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
            releaseYear: response.releaseYear,
            notes: response.notes
        )
    }
}
