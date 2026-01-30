import Foundation

// MARK: - Pagination Meta

struct PaginationMeta: Codable {
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int
    let responseTimeMs: Int?
    let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
        case responseTimeMs = "response_time_ms"
        case count
    }
}

// MARK: - Browse Critters (Paginated)

struct BrowseCritterResponse: Codable, Identifiable {
    let uuid: String
    let name: String
    let memberType: String
    let familyUuid: String?
    let familyName: String?
    let species: String?  // Add
    let variantsCount: Int
    let thumbnailUrl: String?
    
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, species
        case memberType = "member_type"
        case familyUuid = "family_uuid"
        case familyName = "family_name"
        case variantsCount = "variants_count"
        case thumbnailUrl = "thumbnail_url"
    }
}

struct BrowseCrittersAPIResponse: Codable {
    let data: [BrowseCritterResponse]
    let meta: PaginationMeta
}

// MARK: - Critter Variants (for Picker)

struct CritterVariantsResponse: Codable {
    let critter: CritterInfo
    let variants: [VariantResponse]
}

struct CritterInfo: Codable {
    let uuid: String
    let name: String
    let memberType: String
    let birthday: String?
    let familyName: String?
    let familyUuid: String?
    let species: String?  // Add
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, birthday, species
        case memberType = "member_type"
        case familyName = "family_name"
        case familyUuid = "family_uuid"
    }
}

struct CritterVariantsAPIResponse: Codable {
    let data: CritterVariantsResponse
    let meta: ResponseMeta?
}

struct ResponseMeta: Codable {
    let responseTimeMs: Int?
    let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case responseTimeMs = "response_time_ms"
        case count
    }
}

// MARK: - Search Results (Flat Variants)

struct SearchResultResponse: Codable, Identifiable {
    let variantUuid: String
    let variantName: String
    let critterUuid: String?
    let critterName: String?
    let familyUuid: String?
    let familyName: String?
    let species: String?  // Add
    let memberType: String?
    let birthday: String?
    let imageUrl: String?
    let thumbnailUrl: String?
    let setName: String?
    let releaseYear: Int?
    
    var id: String { variantUuid }
    
    enum CodingKeys: String, CodingKey {
        case variantUuid = "variant_uuid"
        case variantName = "variant_name"
        case critterUuid = "critter_uuid"
        case critterName = "critter_name"
        case familyUuid = "family_uuid"
        case familyName = "family_name"
        case species
        case memberType = "member_type"
        case imageUrl = "image_url"
        case thumbnailUrl = "thumbnail_url"
        case setName = "set_name"
        case releaseYear = "release_year"
        case birthday
    }
}

struct SearchAPIResponse: Codable {
    let data: [SearchResultResponse]
    let meta: PaginationMeta
}

// MARK: - Families (Updated)

struct FamilyBrowseResponse: Codable, Identifiable {
    let uuid: String
    let name: String
    let slug: String
    let species: String?
    let imageUrl: String?
    let crittersCount: Int
    
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, slug, species
        case imageUrl = "image_url"
        case crittersCount = "critters_count"
    }
}

struct FamiliesAPIResponse: Codable {
    let data: [FamilyBrowseResponse]
    let meta: ResponseMeta?
}

// MARK: - Single Family with Critters

struct FamilyDetailCritter: Codable, Identifiable {
    let uuid: String
    let name: String
    let memberType: String
    let species: String?  // Add
    let variantsCount: Int
    let thumbnailUrl: String?
    
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, species
        case memberType = "member_type"
        case variantsCount = "variants_count"
        case thumbnailUrl = "thumbnail_url"
    }
}

struct FamilyDetailResponse: Codable {
    let uuid: String
    let name: String
    let slug: String
    let species: String?
    let description: String?
    let imageUrl: String?
    let critters: [FamilyDetailCritter]
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, slug, species, description, critters
        case imageUrl = "image_url"
    }
}

struct FamilyDetailAPIResponse: Codable {
    let data: FamilyDetailResponse
    let meta: ResponseMeta?
}
