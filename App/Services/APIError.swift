//
//  APIError.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-26.
//


import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case rateLimited
    case notFound(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .notFound(let message):
            return message
        }
    }
}