import SwiftUI

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchProjects() {
        guard let url = URL(string: Endpoints.getListProjects) else {
            self.errorMessage = "URL inválida"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                
                // Validar y agregar el token de autorización
                if let token = UserManager.shared.authToken {
                    print("Token enviado: \(token)")
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                } else {
                    throw NetworkLocalizedError.unauthorized
                }
                
                print("Request: \(request)")
                
                // Realizar la solicitud
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Depuración: Mostrar respuesta en consola
                print("Response: \(response)")
                print("Data: \(String(data: data, encoding: .utf8) ?? "No data")")
                
                // Validar código de estado HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkLocalizedError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkLocalizedError.httpError(httpResponse.statusCode)
                }
                
                // Decodificar la respuesta
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                self.projects = try decoder.decode([Project].self, from: data)
                
            } catch {
                print("Error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
            
            self.isLoading = false
        }
    }
}
