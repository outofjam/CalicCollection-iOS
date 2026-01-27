//
//  NetworkConfig.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-27.
//


import Foundation

/// Centralized network configuration for all API calls
enum NetworkConfig {
    // MARK: - Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60
    
    // MARK: - Retry Configuration
    static let maxRetries = 3
    static let retryDelay: TimeInterval = 1.0
    static let retryMultiplier: Double = 2.0 // Exponential backoff
    
    // MARK: - Retryable Status Codes
    static let retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    
    // MARK: - Configured URLSession
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        
        // Timeouts
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        
        // Caching
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil // We handle image caching separately
        
        // Connection
        config.waitsForConnectivity = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        
        return URLSession(configuration: config)
    }()
    
    // MARK: - Request Helper with Retry
    static func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error?
        var delay = retryDelay
        
        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                
                // Check if we should retry based on status code
                if let httpResponse = response as? HTTPURLResponse,
                   retryableStatusCodes.contains(httpResponse.statusCode) {
                    
                    if attempt < maxRetries - 1 {
                        print("⚠️ Retryable status \(httpResponse.statusCode), attempt \(attempt + 1)/\(maxRetries)")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        delay *= retryMultiplier
                        continue
                    }
                }
                
                return (data, response)
                
            } catch let error as URLError where error.code == .timedOut || 
                                                 error.code == .networkConnectionLost ||
                                                 error.code == .notConnectedToInternet {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    print("⚠️ Network error: \(error.localizedDescription), attempt \(attempt + 1)/\(maxRetries)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay *= retryMultiplier
                    continue
                }
            } catch {
                throw error // Non-retryable error
            }
        }
        
        throw lastError ?? APIError.invalidResponse
    }
}