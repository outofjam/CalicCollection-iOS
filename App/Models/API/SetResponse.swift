import Foundation

/// API response for set lookup
struct SetResponse: Codable {
    let set: SetInfo
    let variants: [SetVariant]
    let variantsCount: Int
    
    enum CodingKeys: String, CodingKey {
        case set, variants
        case variantsCount = "variants_count"
    }
}

struct SetInfo: Codable {
    let uuid: String
    let epochId: String
    let name: String
    let releaseYear: Int?
    let description: String?
    let barcode: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case epochId = "epoch_id"
        case name
        case releaseYear = "release_year"
        case description, barcode
    }
}

struct SetVariant: Codable, Identifiable {
    let uuid: String
    let name: String
    let sku: String?
    let barcode: String?
    let imageURL: String?
    let thumbnailURL: String?
    let releaseYear: Int?
    let notes: String?
    let critter: SetCritter
    
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, sku, barcode, notes, critter
        case imageURL = "image_url"
        case thumbnailURL = "thumbnail_url"
        case releaseYear = "release_year"
    }
}

struct SetCritter: Codable {
    let uuid: String
    let name: String
    let memberType: String
    let role: String?
    let family: SetFamily
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, role, family
        case memberType = "member_type"
    }
}

struct SetFamily: Codable {
    let uuid: String
    let name: String
    let species: String?
}

/// Service for fetching sets by barcode
class SetService {
    static let shared = SetService()
    
    private var baseURL: String {
        Config.apiBaseURL
    }
    
    private init() {}
    
    func fetchSetByBarcode(_ barcode: String) async throws -> SetResponse {
        let urlString = "\(baseURL)/sets/barcode/\(barcode)"
        
        print("🔍 Fetching set with barcode: \(barcode)")
        print("🌐 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await NetworkConfig.performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                print("❌ Set not found (404)")
                throw APIError.notFound(message: "No set found with this barcode")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("✅ Response: \(responseString.prefix(200))...")
        }
        
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(SetResponseWrapper.self, from: data)
        print("✅ Successfully decoded set: \(wrapper.data.set.name)")
        return wrapper.data
    }
}

/// Wrapper for API response format
private struct SetResponseWrapper: Codable {
    let data: SetResponse
}
