//
//  APIStats.swift
//  CaliCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-24.
//


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
    
    private let baseURL = "https://calicoprod.thetechnodro.me/api/v1"
    
    private init() {}
    
    func fetchStats() async throws -> APIStats {
        let urlString = "\(baseURL)/stats"
        
        guard let url = URL(string: urlString) else {
            throw StatsServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StatsServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StatsServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(StatsResponseWrapper.self, from: data)
        return wrapper.data
    }
}

private struct StatsResponseWrapper: Codable {
    let data: APIStats
}

enum StatsServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        }
    }
}
