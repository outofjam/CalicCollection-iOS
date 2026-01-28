import Foundation
import SwiftData

/// Cached family data (synced periodically, small dataset)
@Model
final class Family {
    @Attribute(.unique) var uuid: String
    var name: String
    var slug: String
    var species: String?
    var familyDescription: String?
    var imageURL: String?
    var crittersCount: Int
    var lastSynced: Date

    init(
        uuid: String,
        name: String,
        slug: String,
        species: String? = nil,
        familyDescription: String? = nil,
        imageURL: String? = nil,
        crittersCount: Int = 0,
        lastSynced: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.slug = slug
        self.species = species
        self.familyDescription = familyDescription
        self.imageURL = imageURL
        self.crittersCount = crittersCount
        self.lastSynced = lastSynced
    }

    /// Create from new browse API response
    convenience init(from response: FamilyBrowseResponse) {
        self.init(
            uuid: response.uuid,
            name: response.name,
            slug: response.slug,
            species: response.species,
            imageURL: response.imageUrl,
            crittersCount: response.crittersCount
        )
    }
    
    /// Create from legacy API response (for backwards compatibility)
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
