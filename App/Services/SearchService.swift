import Foundation

/// Service for searching critters (online only)
class SearchService {
    static let shared = SearchService()
    
    private var baseURL: String {
        Config.apiBaseURL
    }
    
    private init() {}
    
    /// Search critters across variant names, critter names, and family names
    /// Returns results grouped by critter with matching variants
    /// - Parameters:
    ///   - query: Search query (min 2 characters)
    ///   - page: Page number (default 1)
    ///   - perPage: Critters per page (default 20)
    func search(
        query: String,
        page: Int = 1,
        perPage: Int = 20
    ) async throws -> CritterSearchAPIResponse {
        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw APIError.invalidURL
        }
        
        let urlString = "\(baseURL)/search?q=\(encodedQuery)&page=\(page)&per_page=\(perPage)"
        
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
        
        if httpResponse.statusCode == 422 {
            throw APIError.validationError(message: "Search query must be 2-100 characters")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(CritterSearchAPIResponse.self, from: data)
    }
}
