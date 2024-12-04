//
//  NetworkManager.swift
//  QGS
//
//  Created by Edin Martinez on 12/2/24.
//

import Foundation



// Modelo para la respuesta completa
struct LoginResponse: Decodable {
    let status: Bool
    let message: String
    let user: User
    let name: String
    let sysconf: Int
    let email: String
    let token: String
}

// Modelo para el usuario
struct User: Decodable {
    let id: Int
    let name: String
    let type: String
    let sysconfId: Int
    let code: String
    let email: String
    let emailVerifiedAt: String?
    let createdAt: String
    let updatedAt: String
    let sysconfs: [Sysconf]
    let employee: Employee
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case sysconfId = "sysconf_id"
        case code
        case email
        case emailVerifiedAt = "email_verified_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sysconfs
        case employee
    }
}





class APIService {
    static let shared = APIService()
    
    private let baseURL = Endpoints.login
    
    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch {
            completion(.failure(error))
            return
        }
       
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
