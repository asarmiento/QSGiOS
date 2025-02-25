enum NetworkLocalizedError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int, String)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .unauthorized:
            return "No autorizado"
        case .notFound:
            return "Recurso no encontrado"
        case .serverError(let code, let message):
            return "Error del servidor (\(code)): \(message)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Error al procesar datos: \(error.localizedDescription)"
        }
    }
} 