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
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("JSON recibido (primeros 200 caracteres): \(jsonString.prefix(200))...")
                }
                
                // Intentar decodificar manualmente primero para verificar la estructura
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let firstProject = json.first {
                    print("Claves del primer proyecto: \(firstProject.keys)")
                    print("Tipo de budget: \(type(of: firstProject["budget"] ?? "desconocido"))")
                }
                
                // Decodificar los proyectos directamente con el modelo actualizado
                let decoder = JSONDecoder()
                
                do {
                    self.projects = try decoder.decode([Project].self, from: data)
                    print("Proyectos cargados: \(self.projects.count)")
                } catch let decodingError {
                    print("Error de decodificación: \(decodingError)")
                    
                    // Si falla la decodificación directa, intentar procesar manualmente
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        var newProjects: [Project] = []
                        
                        for projectData in json {
                            let id = projectData["id"] as? Int ?? 0
                            let name = projectData["name"] as? String ?? ""
                            let address = projectData["address"] as? String ?? ""
                            let altitude = projectData["altitude"] as? String ?? ""
                            let longitude = projectData["longitude"] as? String ?? ""
                            let status = projectData["status"] as? Int ?? 0
                            
                            // Manejar el budget que puede ser String o Double
                            var budget: Double = 0.0
                            if let budgetDouble = projectData["budget"] as? Double {
                                budget = budgetDouble
                            } else if let budgetString = projectData["budget"] as? String,
                                      let budgetValue = Double(budgetString) {
                                budget = budgetValue
                            }
                            
                            let createdAt = projectData["created_at"] as? String
                            let updatedAt = projectData["updated_at"] as? String
                            let hours = projectData["hours"] as? String
                            let month = projectData["month"] as? String
                            let year = projectData["year"] as? String
                            let sysconfId = projectData["sysconf_id"] as? Int
                            
                            let project = Project(
                                id: id,
                                name: name,
                                address: address,
                                altitude: altitude,
                                longitude: longitude,
                                status: status,
                                budget: budget,
                                createdAt: createdAt,
                                updatedAt: updatedAt,
                                hours: hours,
                                month: month,
                                year: year,
                                sysconfId: sysconfId
                            )
                            
                            newProjects.append(project)
                        }
                        
                        self.projects = newProjects
                        print("Proyectos cargados manualmente: \(self.projects.count)")
                    } else {
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
