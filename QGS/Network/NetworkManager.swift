//
//  NetworkManager.swift
//  QGS
//
//  Created by Edin Martinez on 12/2/24.
//

import Foundation
import OSLog

class NetworkManager {
    static let shared = NetworkManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QGS", category: "Network")
    
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    func request<T: Decodable>(_ endpoint: String,
                              method: String = "GET",
                              params: [String: Any]? = nil,
                              retryCount: Int = 0) async throws -> T {
        guard let url = URL(string: endpoint) else {
            self.logger.error("URL inválida: \(endpoint)")
            throw NetworkLocalizedError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let token = UserManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let params = params {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        }
        
        do {
            self.logger.debug("Iniciando request: \(endpoint)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("Respuesta inválida")
                throw NetworkLocalizedError.invalidResponse
            }
            
            // Log response
            self.logger.debug("Respuesta recibida: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                self.logger.debug("Datos recibidos: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    self.logger.error("Error de decodificación: \(error.localizedDescription)")
                    throw NetworkLocalizedError.decodingError(error)
                }
            case 401:
                self.logger.error("Error de autenticación")
                throw NetworkLocalizedError.unauthorized
            case 503:
                // Retry logic for server errors
                if retryCount < self.maxRetries {
                    self.logger.warning("Reintentando request (\(retryCount + 1)/\(self.maxRetries))")
                    try await Task.sleep(nanoseconds: UInt64(self.retryDelay * 1_000_000_000))
                    return try await self.request(endpoint, 
                                                method: method, 
                                                params: params, 
                                                retryCount: retryCount + 1)
                }
                let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
                throw NetworkLocalizedError.serverError(httpResponse.statusCode, errorMessage)
            default:
                self.logger.error("Error del servidor: \(httpResponse.statusCode)")
                let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
                throw NetworkLocalizedError.serverError(httpResponse.statusCode, errorMessage)
            }
        } catch {
            if let networkError = error as? NetworkError {
                throw NetworkLocalizedError
            }
            
            // Retry for network errors
            if retryCount < self.maxRetries {
                self.logger.warning("Error de red, reintentando (\(retryCount + 1)/\(self.maxRetries))")
                try await Task.sleep(nanoseconds: UInt64(self.retryDelay * 1_000_000_000))
                return try await self.request(endpoint, 
                                            method: method, 
                                            params: params, 
                                            retryCount: retryCount + 1)
            }
            
            self.logger.error("Error de red: \(error.localizedDescription)")
            throw NetworkLocalizedError.networkError(error)
        }
    }
}



