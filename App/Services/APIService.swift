import Foundation

/// Service to handle all API communication with Laravel backend
class APIService {
    static let shared = APIService()
    
    private var baseURL: String {
        Config.apiBaseURL
    }
    
    private init() {}
    
    // MARK: - Critters
    
    /// Fetch all critters with variants from API
    func fetchCritters() async throws -> [CritterResponse] {
        guard let url = URL(string: "\(baseURL)/critters") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CritterAPIResponse.self, from: data)
        return response.data
    }
    
    // MARK: - Families
    
    /// Fetch all families from API
    func fetchFamilies() async throws -> [FamilyResponse] {
        guard let url = URL(string: "\(baseURL)/families") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(FamilyAPIResponse.self, from: data)
        return response.data
    }
}
