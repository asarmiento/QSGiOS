import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case noData
    case decodingError(Error)
    case serverError(Int)
    case networkError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("URL_INVALID", comment: "")
        case .invalidResponse:
            return NSLocalizedString("RESPONSE_INVALID", comment: "")
        case .unauthorized:
            return NSLocalizedString("AUTH_ERROR", comment: "")
        case .noData:
            return NSLocalizedString("NO_DATA", comment: "")
        case .serverError(let code):
            return String(format: NSLocalizedString("SERVER_ERROR", comment: ""), code)
        case .networkError(let error):
            return String(format: NSLocalizedString("NETWORK_ERROR", comment: ""), error.localizedDescription)
        case .decodingError(let error):
            return String(format: NSLocalizedString("DECODING_ERROR", comment: ""), error.localizedDescription)
        case .apiError(let message):
            return message
        }
    }
} 