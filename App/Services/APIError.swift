import Foundation

/// Errors that can occur during API calls
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    case rateLimited
    case notFound(message: String)
    case validationError(message: String)
    case offline
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .notFound(let message):
            return message
        case .validationError(let message):
            return message
        case .offline:
            return "No internet connection. Please check your network."
        }
    }
}
