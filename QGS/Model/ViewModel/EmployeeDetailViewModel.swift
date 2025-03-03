import Foundation

@MainActor
class EmployeeDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum EmployeeUpdateError: Error, LocalizedError {
        case networkError(String)
        case serverError(Int, String)
        case decodingError
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return NSLocalizedString("Error de red: \(message)", comment: "")
            case .serverError(let code, let message):
                return NSLocalizedString("Error del servidor (\(code)): \(message)", comment: "")
            case .decodingError:
                return NSLocalizedString("Error al procesar la respuesta del servidor", comment: "")
            case .invalidData:
                return NSLocalizedString("Datos inválidos", comment: "")
            }
        }
    }
    
    func updateEmployee(id: Int, name: String, email: String, phone: String, status: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Validar datos
        guard !name.isEmpty, !email.isEmpty, !phone.isEmpty else {
            isLoading = false
            errorMessage = NSLocalizedString("Todos los campos son obligatorios", comment: "")
            completion(.failure(EmployeeUpdateError.invalidData))
            return
        }
        
        Task {
            do {
                let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/update-employee/\(id)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                // Obtener el token de autenticación
                if let token = UserManager.shared.authToken {
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                } else {
                    throw EmployeeUpdateError.networkError(NSLocalizedString("No hay token de autenticación", comment: ""))
                }
                
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                // Crear el cuerpo de la solicitud
                let parameters: [String: Any] = [
                    "name": name,
                    "email": email,
                    "phone": phone,
                    "status": status
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                
                // Realizar la solicitud
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Validar el código de estado HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw EmployeeUpdateError.networkError(NSLocalizedString("Respuesta inválida del servidor", comment: ""))
                }
                
                if httpResponse.statusCode != 200 {
                    // Intentar obtener el mensaje de error del servidor
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorJson["message"] as? String {
                        throw EmployeeUpdateError.serverError(httpResponse.statusCode, message)
                    } else {
                        throw EmployeeUpdateError.serverError(httpResponse.statusCode, NSLocalizedString("Error desconocido", comment: ""))
                    }
                }
                
                // Éxito
                completion(.success(()))
                
            } catch {
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
            
            self.isLoading = false
        }
    }
} 