import Foundation

/// Service for browsing critters with pagination (online only)
class BrowseService {
    static let shared = BrowseService()
    
    private var baseURL: String {
        Config.apiBaseURL
    }
    
    private init() {}
    
    // MARK: - Browse Critters (Paginated)
    
    /// Fetch paginated critters for browsing
    /// - Parameters:
    ///   - page: Page number (default 1)
    ///   - perPage: Items per page (default 30)
    ///   - familyUuid: Optional family filter
    func fetchCritters(
        page: Int = 1,
        perPage: Int = 30,
        familyUuid: String? = nil
    ) async throws -> BrowseCrittersAPIResponse {
        var urlString = "\(baseURL)/critters?page=\(page)&per_page=\(perPage)"
        
        if let familyUuid = familyUuid {
            urlString += "&family=\(familyUuid)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        AppLogger.networkRequest(urlString)
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await NetworkConfig.performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        AppLogger.networkResponse(status: httpResponse.statusCode, url: urlString)
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(BrowseCrittersAPIResponse.self, from: data)
    }
    
    // MARK: - Critter Variants (for Picker)
    
    /// Fetch variants for a specific critter
    func fetchCritterVariants(critterUuid: String) async throws -> CritterVariantsResponse {
        let urlString = "\(baseURL)/critters/\(critterUuid)/variants"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        AppLogger.networkRequest(urlString)
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await NetworkConfig.performRequest(request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Raw API response: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        AppLogger.networkResponse(status: httpResponse.statusCode, url: urlString)
        
        if httpResponse.statusCode == 404 {
            throw APIError.notFound(message: "Critter not found")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(CritterVariantsAPIResponse.self, from: data)
        return apiResponse.data
    }
    
    // MARK: - Families
    
    /// Fetch all families with critter counts
    func fetchFamilies() async throws -> [FamilyBrowseResponse] {
        let urlString = "\(baseURL)/families"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        AppLogger.networkRequest(urlString)
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await NetworkConfig.performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        AppLogger.networkResponse(status: httpResponse.statusCode, url: urlString)
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(FamiliesAPIResponse.self, from: data)
        return apiResponse.data
    }
    
    /// Fetch single family with its critters
    func fetchFamily(uuid: String) async throws -> FamilyDetailResponse {
        let urlString = "\(baseURL)/families/\(uuid)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        AppLogger.networkRequest(urlString)
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await NetworkConfig.performRequest(request)
        
        // ADD THIS DEBUG LINE
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Family API response: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        AppLogger.networkResponse(status: httpResponse.statusCode, url: urlString)
        
        if httpResponse.statusCode == 404 {
            throw APIError.notFound(message: "Family not found")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        
        // ADD THIS DEBUG BLOCK
        do {
            let apiResponse = try decoder.decode(FamilyDetailAPIResponse.self, from: data)
            return apiResponse.data
        } catch {
            print("❌ Decoding error: \(error)")
            throw error
        }
    }
}
