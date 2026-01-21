import Foundation

/// API response for a critter variant (specific product release)
struct VariantResponse: Codable, Identifiable {
    let uuid: String
    let critterId: String
    let name: String
    let sku: String?
    let barcode: String?
    let imageUrl: String?
    let releaseYear: Int?
    let notes: String?
    let createdAt: String
    let updatedAt: String
    
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case critterId = "critter_id"
        case name, sku, barcode
        case imageUrl = "image_url"
        case releaseYear = "release_year"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
