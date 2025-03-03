//
//  APIServiceRecord.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/6/24.
//
import Foundation

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchProjects() {

        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let accessToken = UserManager.shared.authToken, !accessToken.isEmpty else {
                    print("Token de autenticación no válido o vacío.")
                    self.errorMessage = "Token no válido o ausente."
                    return
                }
                print("Token usado: \(accessToken)")
                let url = URL(string: "\(EndPoints.getListProjects)")!
                print("obtener el usuario o el token. url: \(url)")
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                print("request headers: \(request.allHTTPHeaderFields ?? [:])")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Validar el código de estado HTTP
                if let httpResponse = response as? HTTPURLResponse {
                    print("Código de estado HTTP: \(httpResponse.statusCode)")
                    print("Headers de respuesta: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode != 200 {
                        let responseBody = String(data: data, encoding: .utf8) ?? "No se pudo leer el cuerpo de la respuesta"
                        print("Cuerpo de la respuesta: \(responseBody)")
                        throw URLError(.badServerResponse)
                    }
                }


                // Imprimir la respuesta para depuración
//                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("JSON recibido: \(jsonString.prefix(200))...")
//                }
                
                // Intentar decodificar manualmente primero para verificar la estructura
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let firstProject = json.first {
                    print("Claves del primer proyecto: \(firstProject.keys)")
                }
                
                // Decodificar los proyectos
                let decoder = JSONDecoder()
                
                // Configurar el decodificador para manejar claves en snake_case
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                do {
                    self.projects = try decoder.decode([Project].self, from: data)
                    print("Proyectos cargados: \(self.projects.count)")
                } catch let decodingError {
                    print("Error de decodificación: \(decodingError)")
                    
                    // Intentar una decodificación alternativa
                    let alternativeDecoder = JSONDecoder()
                    // Sin estrategia de conversión de claves
                    
                    do {
                        // Definir un modelo alternativo para la decodificación
                        struct ProjectDTO: Codable {
                            let id: Int
                            let name: String
                            let address: String
                            let altitude: String
                            let longitude: String
                            let status: Int
                            let created_at: String
                            let updated_at: String
                            let hours: String?
                            let month: String?
                        }
                        
                        let dtos = try alternativeDecoder.decode([ProjectDTO].self, from: data)
                        
                        // Convertir DTOs a modelos Project
                        self.projects = dtos.map { dto in
                            Project(
                                id: dto.id,
                                name: dto.name,
                                address: dto.address,
                                altitude: dto.altitude,
                                longitude: dto.longitude,
                                status: dto.status,
                                createdAt: dto.created_at,
                                updatedAt: dto.updated_at,
                                hours: dto.hours,
                                month: dto.month
                            )
                        }
                        
                        print("Proyectos cargados con método alternativo: \(self.projects.count)")
                    } catch let alternativeError {
                        print("Error en decodificación alternativa: \(alternativeError)")
                        throw decodingError
                    }
                }
                
            } catch let error as URLError {
                print("Error de red: \(error.localizedDescription) - Código: \(error.code)")
                self.errorMessage = "Error de red: \(error.localizedDescription)"
            } catch {
                print("Error inesperado: \(error)")
                self.errorMessage = "Error inesperado: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
      
    }
  
}
