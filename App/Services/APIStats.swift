import Foundation

struct APIStats: Codable {
    let crittersCount: Int
    let variantsCount: Int
    let setsCount: Int
    
    enum CodingKeys: String, CodingKey {
        case crittersCount = "critters_count"
        case variantsCount = "variants_count"
        case setsCount = "sets_count"
    }
}

class StatsService {
    static let shared = StatsService()
    
    private var baseURL: String {
        Config.apiBaseURL
    }
    
    private init() {}
    
    func fetchStats() async throws -> APIStats {
        let urlString = "\(baseURL)/stats"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(StatsResponseWrapper.self, from: data)
        return wrapper.data
    }
}

private struct StatsResponseWrapper: Codable {
    let data: APIStats
}
