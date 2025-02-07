import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case unauthorized
    case noData
    case decodingError(Error)
    case serverError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "No se pudo obtener respuesta del servidor"
        case .invalidData:
            return "Los datos recibidos no son válidos"
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión nuevamente"
        case .noData:
            return "No se recibieron datos"
        case .decodingError(let error):
            return "Error al procesar datos: \(error.localizedDescription)"
        case .serverError(let code):
            return "Error del servidor (\(code))"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
} 