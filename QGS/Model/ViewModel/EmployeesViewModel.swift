//
//  EmployeesViewModel.swift
//  QGS
//
//  Created by Anwar Sarmiento on 2/27/25.
//

import Foundation

@MainActor
class EmployeesViewModel: ObservableObject {
    @Published var employees: [EmployeeCodable] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchEmployees() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/list-employees")!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                // Obtener el token de autenticación
                if let token = UserManager.shared.authToken {
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                } else {
                    throw NSError(domain: "EmployeesViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay token de autenticación"])
                }
                
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Validar el código de estado HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "EmployeesViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del servidor"])
                }
                
                if httpResponse.statusCode != 200 {
                    // Intentar obtener el mensaje de error del servidor
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorJson["message"] as? String {
                        throw NSError(domain: "EmployeesViewModel", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                    } else {
                        throw NSError(domain: "EmployeesViewModel", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor: \(httpResponse.statusCode)"])
                    }
                }
                
                // Decodificar la respuesta
                let decoder = JSONDecoder()
                
                // Usar el modelo EmployeeCodable que ya tiene definidas las CodingKeys
                self.employees = try decoder.decode([EmployeeCodable].self, from: data)
                
                // Filtrar empleados activos (status = 1)
                self.employees = self.employees.filter { $0.status == 1 }
                
                print("Empleados cargados: \(self.employees.count)")
                
            } catch {
                print("Error al cargar empleados: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
            
            self.isLoading = false
        }
    }
}

