import Foundation

/// API response for a critter (base character template)
struct CritterResponse: Codable, Identifiable {
    let uuid: String
    let familyId: String
    let name: String
    let memberType: String
    let role: String?
    let barcode: String?
    let createdAt: String
    let updatedAt: String
    
    // Nested relationships
    let family: FamilyResponse?
    let variantsCount: Int
    let variants: [VariantResponse]?
    
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case familyId = "family_id"
        case name
        case memberType = "member_type"
        case role, barcode
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case family
        case variantsCount = "variants_count"
        case variants
    }
}

/// Wrapper for critters API response
struct CritterAPIResponse: Codable {
    let data: [CritterResponse]
}

/// Wrapper for families API response
struct FamilyAPIResponse: Codable {
    let data: [FamilyResponse]
}
