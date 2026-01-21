import Foundation

/// API response for a Calico Critters family
struct FamilyResponse: Codable, Identifiable {
    let uuid: String
    let name: String
    let slug: String
    let species: String
    let description: String?
    let imageUrl: String?
    let createdAt: String
    let updatedAt: String
    
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, slug, species, description
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
