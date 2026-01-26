import Foundation


/// API response for a critter variant (specific product release)
struct VariantResponse: Codable, Identifiable {
    let uuid: String
    let critterId: String
    let name: String
    let sku: String?
    let barcode: String?
    let imageUrl: String?
    let thumbnailUrl: String?
    let releaseYear: Int?
    let notes: String?
    let setId: String?
    let setName: String?
    let epochId: String?
    let createdAt: String
    let updatedAt: String
    let isPrimary: Bool?
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case critterId = "critter_id"
        case name, sku, barcode
        case imageUrl = "image_url"
        case thumbnailUrl = "thumbnail_url"
        case releaseYear = "release_year"
        case notes
        case setId = "set_id"
        case setName = "set_name"
        case epochId = "epoch_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isPrimary = "is_primary" // ADD THIS
    }
}
