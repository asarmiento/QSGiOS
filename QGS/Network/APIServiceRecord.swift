//
//  APIServiceRecord.swift
//  QGS
//
//  Created by Edin Martinez on 12/6/24.
//
import Foundation

class APIServiceRecord {
    static let shared = APIServiceRecord()
    // Contexto para cambios

    private let baseURL = Endpoints.storeRecord
    
    func record(params: [String: Any], completion: @escaping (Result<RecordResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        guard let accessToken = UserManager.shared.authToken else {
            print("No se pudo obtener el usuario o el token.")
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        } catch {
            completion(.failure(NetworkError.networkError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NetworkError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(RecordResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(NetworkError.decodingError(error)))
            }
        }.resume()
    }
}
