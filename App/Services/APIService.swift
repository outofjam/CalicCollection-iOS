import Foundation

/// Service to handle all API communication with Laravel backend
class APIService {
    static let shared = APIService()
    
    private var baseURL: String {
        Config.apiBaseURL
    }
    
    private init() {}
    
    // MARK: - Critters
    
    func fetchCritters() async throws -> [CritterResponse] {
        guard let url = URL(string: "\(baseURL)/critters") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await NetworkConfig.performRequest(request)
        let response = try JSONDecoder().decode(CritterAPIResponse.self, from: data)
        return response.data
    }
    
    // MARK: - Families
    
    func fetchFamilies() async throws -> [FamilyResponse] {
        guard let url = URL(string: "\(baseURL)/families") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await NetworkConfig.performRequest(request)
        let response = try JSONDecoder().decode(FamilyAPIResponse.self, from: data)
        return response.data
    }
    
    // MARK: - Reports
    
    func submitReport(
        variantUuid: String,
        issueType: ReportIssueType,
        details: String?,
        suggestedCorrection: String?
    ) async throws -> String {
        let urlString = "\(baseURL)/variants/report"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let report = ReportRequest(
            variantUuid: variantUuid,
            issueType: issueType,
            details: details,
            suggestedCorrection: suggestedCorrection,
            deviceId: Config.deviceId
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(report)
        
        let (data, response) = try await NetworkConfig.performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            throw APIError.rateLimited
        }
        
        guard httpResponse.statusCode == 201 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let reportResponse = try decoder.decode(ReportResponse.self, from: data)
        
        return reportResponse.message
    }
}
