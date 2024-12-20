import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized
    case apiError(String)
    case networkError(Error)
    case decodingError(Error)
    
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
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Error al procesar datos: \(error.localizedDescription)"
        }
    }
} 