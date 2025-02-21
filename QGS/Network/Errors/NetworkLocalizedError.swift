import Foundation

enum NetworkLocalizedError: LocalizedError {
       case invalidURL
       case invalidResponse
       case decodingError(Error)
       case unauthorized
       case serverError(Int, String)
       case networkError(Error)
       
       var errorDescription: String? {
           switch self {
           case .invalidURL:
               return "La URL es inválida."
           case .invalidResponse:
               return "La respuesta del servidor es inválida."
           case .decodingError(let error):
               return "Error de decodificación: \(error.localizedDescription)"
           case .unauthorized:
               return "No autorizado."
           case .serverError(let code, let message):
               return "Error del servidor \(code): \(message)"
           case .networkError(let error):
               return "Error de red: \(error.localizedDescription)"
           }
       }
   }
