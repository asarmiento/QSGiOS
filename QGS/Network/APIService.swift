import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = EndPoints.login
    
    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(NetworkError.networkError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.networkError(error)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            // Debug: Imprimir respuesta JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Respuesta JSON: \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(LoginResponse.self, from: data)
                DispatchQueue.main.async {
                    if response.status {
                        completion(.success(response))
                    } else {
                        completion(.failure(NetworkError.apiError(response.message)))
                    }
                }
            } catch {
                print("Error de decodificación: \(error)")
                if let jsonString = String(data: data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let errorResponse = try? JSONDecoder().decode(LoginResponse.self, from: jsonData) {
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.apiError(errorResponse.message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.decodingError(error)))
                    }
                }
            }
        }.resume()
    }
    
    func register(name: String, email: String, phone: String, card: String, altitude: Double, longitude: Double, nameWorkType: String, password: String, nameProject: String, budget: Double, address: String, completion: @escaping (Result<RegisterResponse, Error>) -> Void) {
        guard let url = URL(string: EndPoints.storeRegister) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone,
            "card": card,
            "altitude": altitude,
            "longitude": longitude,
            "name_work_type": nameWorkType,
            "password": password,
            "name_project": nameProject,
            "budget": budget,
            "address": address
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(NetworkError.networkError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.networkError(error)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            // Debug: Imprimir respuesta JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Respuesta JSON registro: \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(RegisterResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                print("Error de decodificación registro: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.decodingError(error)))
                }
            }
        }.resume()
    }
} 
