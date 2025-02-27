import SwiftUI

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
                let url = URL(string: Endpoints.getListProjects)!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                 // Agregar el token de autorización
                if let token = UserManager.shared.authToken {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                print("Request: \(request)")
                let (data, response) = try await URLSession.shared.data(for: request)
                print(String(data: data, encoding: .utf8) ?? "No data")
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkLocalizedError.invalidResponse
                }
                
                let decoder = JSONDecoder()
                self.projects = try decoder.decode([Project].self, from: data)
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
} 
