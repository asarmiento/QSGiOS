//
//  EmployeesViewModel.swift
//  QGS
//
//  Created by Anwar Sarmiento on 2/27/25.
//

import Foundation
import Combine

@MainActor
class EmployeesViewModel: ObservableObject {
    @Published var employees: [EmployeeCodable] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchEmployees() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            guard let token = UserManager.shared.authToken else {
                DispatchQueue.main.async {
                    self.errorMessage = "No hay token de autenticación"
                    self.isLoading = false
                }
                return
            }
            
            let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/list-employees")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let employees = try decoder.decode([EmployeeCodable].self, from: data)
                
                DispatchQueue.main.async {
                    self.employees = employees
                    self.isLoading = false
                }
            } else if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    self.errorMessage = "No autorizado. Por favor, inicie sesión nuevamente."
                    self.isLoading = false
                }
            } else {
                // Intentar decodificar el mensaje de error
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorResponse["message"] {
                    DispatchQueue.main.async {
                        self.errorMessage = message
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error del servidor: \(httpResponse.statusCode)"
                        self.isLoading = false
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

