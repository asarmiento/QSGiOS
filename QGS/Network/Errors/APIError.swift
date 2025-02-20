import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "No se recibieron datos del servidor"
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión nuevamente"
        case .apiError(let message):
            return message
        }
    }
} 