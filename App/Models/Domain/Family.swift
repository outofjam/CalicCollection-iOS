import Foundation
import SwiftData

/// Browse cache: Critter family (temporary, synced from API)
@Model
final class Family {
    @Attribute(.unique) var uuid: String
    var name: String
    var slug: String
    var species: String
    var familyDescription: String?
    var imageURL: String?
    var lastSynced: Date
    
    init(
        uuid: String,
        name: String,
        slug: String,
        species: String,
        familyDescription: String? = nil,
        imageURL: String? = nil,
        lastSynced: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.slug = slug
        self.species = species
        self.familyDescription = familyDescription
        self.imageURL = imageURL
        self.lastSynced = lastSynced
    }
    
    /// Create from API response
    convenience init(from response: FamilyResponse) {
        self.init(
            uuid: response.uuid,
            name: response.name,
            slug: response.slug,
            species: response.species,
            familyDescription: response.description,
            imageURL: response.imageUrl
        )
    }
}
