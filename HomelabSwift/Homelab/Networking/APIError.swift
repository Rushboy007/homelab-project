import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, body: String)
    case decodingError(Error)
    case unauthorized
    case bothURLsFailed(primaryError: Error, fallbackError: Error)
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service not configured. Please connect first."
        case .invalidURL:
            return "Invalid URL. Check the server address."
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .httpError(let code, let body):
            return "Server error \(code): \(body.isEmpty ? "Unknown error" : body)"
        case .decodingError(let e):
            return "Data parsing error: \(e.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please reconnect."
        case .bothURLsFailed:
            return "Connection failed on both primary and fallback URLs. Check your network."
        case .custom(let msg):
            return msg
        }
    }
}
