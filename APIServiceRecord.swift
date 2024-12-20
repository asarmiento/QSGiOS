class APIServiceRecord {
    static let shared = APIServiceRecord()
    private let baseURL = "https://api.friendlypayroll.net/api"
    
    func storeWorkTime(workData: [String: Any]) async throws -> WorkTimeResponse {
        guard let url = URL(string: "\(baseURL)/projects/store-data-time-work") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: workData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Debug: Imprimir JSON recibido
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON recibido: \(jsonString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                
                do {
                    // Intentar decodificar primero sin convertir snake_case
                    return try decoder.decode(WorkTimeResponse.self, from: data)
                } catch {
                    print("Error inicial de decodificación: \(error)")
                    
                    // Intentar con conversión de snake_case
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    return try decoder.decode(WorkTimeResponse.self, from: data)
                }
            case 401:
                throw APIError.unauthorized
            case 422:
                // Intentar decodificar el mensaje de error de validación
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorJson["message"] as? String {
                    throw APIError.validationError(message: message)
                }
                throw APIError.validationError(message: "Error de validación")
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch {
            throw APIError.networkError(error)
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case validationError(message: String)
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión nuevamente"
        case .validationError(let message):
            return "Error de validación: \(message)"
        case .serverError(let code):
            return "Error del servidor (\(code))"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Error al procesar la respuesta: \(error.localizedDescription)"
        }
    }
} 