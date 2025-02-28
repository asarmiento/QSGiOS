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
                let url = URL(string: "https://api.friendlypayroll.net/public/api/projects/data-projects")!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue("Bearer 2291|DmpJoqafDWBHh40ACzESMNxVZAUL8dSmOweLRokD8e90314a", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Validar el código de estado HTTP
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }

                // Imprimir la respuesta para depuración
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("JSON recibido: \(jsonString.prefix(200))...")
                }
                
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
                
            } catch {
                print("Error detallado: \(error)")
                self.errorMessage = "Error al cargar proyectos: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}
